package rooms

import (
	"GeekMeeting/internal/util"
	"encoding/json"
	"log"
	"sync"
	"time"

	"github.com/pion/rtcp"
	"github.com/pion/webrtc/v3"
)

type peerConnectionState struct {
	user *threadSafeWriter
}

type room struct {
	sync.RWMutex
	once            sync.Once
	peerConnections []peerConnectionState
	trackLocals     map[string]*webrtc.TrackLocalStaticRTP
	free            chan struct{}
	exitTime        time.Time
}

func (r *room) init() {
	r.once.Do(func() {
		go func() {
			timer := time.NewTicker(time.Second * 3)
			defer timer.Stop()
			for {
				select {
				case <-timer.C:
					r.dispatchKeyFrame()
					// timer.Reset(time.Second * 3)
				case <-r.free:
					return
				}
			}
		}()
		// 检测房间到期时间以及房间人数，如果人数为0则停止同步帧并释放这个房间
		go func() {
			timer := time.NewTicker(time.Second * 30)
			defer timer.Stop()
			for range timer.C {
				// log.Println(r.exitTime)
				// log.Println(time.Now())
				if len(r.peerConnections) == 0 || time.Now().After(r.exitTime) {
					// 关闭socket
					r.RLock()
					for index := range r.peerConnections {
						_ = r.peerConnections[index].user.Conn.Close()
					}
					r.RUnlock()
					r.free <- struct{}{}
					return
				}
			}
		}()
	})
}

func (r *room) CheckRoomTimeIsZero() bool {
	return r.exitTime.IsZero()
}

func (r *room) SetEndTime(endTime time.Time) {
	// log.Println("set endTime", endTime)
	r.exitTime = endTime
}

// 房间内广播
func (r *room) Broadcast(msg interface{}) {
	for i := range r.peerConnections {
		if err := r.peerConnections[i].user.WriteJSON(msg); err != nil {
			log.Println("Broadcast Error:", err.Error())
		}
	}
}

// 用户加入房间
func (r *room) userJoin(user *threadSafeWriter) {
	r.Lock()
	defer r.Unlock()
	// 同步房间已加入人员
	for index := range r.peerConnections {
		info := UserEvent{Uid: r.peerConnections[index].user.uid, Name: r.peerConnections[index].user.name, StreamID: r.peerConnections[index].user.streamId}
		event, err := json.Marshal(info)
		if err != nil {
			log.Println(err)
			continue
		}
		_ = user.WriteJSON(&websocketMessage{Event: "join", Data: util.BytesToString(event)})
	}
	r.peerConnections = append(r.peerConnections, peerConnectionState{user})
}

// Add to list of tracks and fire renegotation for all PeerConnections
func (r *room) AddTrack(t *webrtc.TrackRemote) *webrtc.TrackLocalStaticRTP {
	r.Lock()
	defer func() {
		r.Unlock()
		r.SignalPeerConnections()
	}()

	// Create a new TrackLocal with the same codec as our incoming
	trackLocal, err := webrtc.NewTrackLocalStaticRTP(t.Codec().RTPCodecCapability, t.ID(), t.StreamID())
	if err != nil {
		panic(err)
	}

	r.trackLocals[t.ID()] = trackLocal
	return trackLocal
}

// Remove from list of tracks and fire renegotation for all PeerConnections
func (r *room) RemoveTrack(t *webrtc.TrackLocalStaticRTP) {
	r.Lock()
	defer func() {
		r.Unlock()
		r.SignalPeerConnections()
	}()
	delete(r.trackLocals, t.ID())
}

// signalPeerConnections updates each PeerConnection so that it is getting all the expected media tracks
func (r *room) SignalPeerConnections() {
	r.Lock()
	defer func() {
		r.Unlock()
		r.dispatchKeyFrame()
	}()

	attemptSync := func() (tryAgain bool) {
		for i := range r.peerConnections {
			if r.peerConnections[i].user.peerConnection.ConnectionState() == webrtc.PeerConnectionStateClosed {
				r.peerConnections = append(r.peerConnections[:i], r.peerConnections[i+1:]...)
				return true // We modified the slice, start from the beginning
			}

			// map of sender we already are seanding, so we don't double send
			existingSenders := map[string]bool{}

			// log.Println(r.peerConnections[i].user.uid, "sender=", r.peerConnections[i].user.peerConnection.GetSenders())
			for _, sender := range r.peerConnections[i].user.peerConnection.GetSenders() {
				if sender.Track() == nil {
					continue
				}

				existingSenders[sender.Track().ID()] = true

				// If we have a RTPSender that doesn't map to a existing track remove and signal
				if _, ok := r.trackLocals[sender.Track().ID()]; !ok {
					if err := r.peerConnections[i].user.peerConnection.RemoveTrack(sender); err != nil {
						return true
					}
				}
			}
			// log.Println(r.peerConnections[i].user.uid, "receiver=", r.peerConnections[i].user.peerConnection.GetReceivers())
			// Don't receive videos we are sending, make sure we don't have loopback
			for _, receiver := range r.peerConnections[i].user.peerConnection.GetReceivers() {
				if receiver.Track() == nil {
					continue
				}

				existingSenders[receiver.Track().ID()] = true
			}

			// Add all track we aren't sending yet to the PeerConnection
			for trackID := range r.trackLocals {
				if _, ok := existingSenders[trackID]; !ok {
					// log.Println("add sender to user", r.peerConnections[i].user.uid, "streamId:", r.trackLocals[trackID].StreamID())
					if _, err := r.peerConnections[i].user.peerConnection.AddTrack(r.trackLocals[trackID]); err != nil {
						return true
					}
				}
			}
			offer, err := r.peerConnections[i].user.peerConnection.CreateOffer(nil)
			if err != nil {
				return true
			}

			if err = r.peerConnections[i].user.peerConnection.SetLocalDescription(offer); err != nil {
				return true
			}

			offerString, err := json.Marshal(offer)
			if err != nil {
				return true
			}

			if err = r.peerConnections[i].user.WriteJSON(&websocketMessage{
				Event: "offer",
				Data:  util.BytesToString(offerString),
			}); err != nil {
				return true
			}
		}

		return
	}

	for syncAttempt := 0; ; syncAttempt++ {
		if syncAttempt == 25 {
			// Release the lock and attempt a sync in 3 seconds. We might be blocking a RemoveTrack or AddTrack
			go func() {
				time.Sleep(time.Second * 3)
				r.SignalPeerConnections()
			}()
			return
		}

		if !attemptSync() {
			break
		}
	}
}

// dispatchKeyFrame sends a keyframe to all PeerConnections, used everytime a new user joins the call
func (r *room) dispatchKeyFrame() {
	r.Lock()
	defer r.Unlock()

	for i := range r.peerConnections {
		for _, receiver := range r.peerConnections[i].user.peerConnection.GetReceivers() {
			if receiver.Track() == nil {
				continue
			}

			_ = r.peerConnections[i].user.peerConnection.WriteRTCP([]rtcp.Packet{
				&rtcp.PictureLossIndication{
					MediaSSRC: uint32(receiver.Track().SSRC()),
				},
			})
		}
	}
}
