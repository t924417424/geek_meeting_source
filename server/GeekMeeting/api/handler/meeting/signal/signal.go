package signal

import (
	"GeekMeeting/core/sfu/rooms"
	itypes "GeekMeeting/internal/type"
	"GeekMeeting/internal/util"
	meetingDb "GeekMeeting/services/database/mysql/meeting"
	"context"
	"database/sql"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/julienschmidt/httprouter"
	"github.com/pion/webrtc/v3"
)

// 信令服务器
func SignalHandler(ctx context.Context) httprouter.Handle {
	db := ctx.Value(itypes.DatabasesKey).(*sql.DB)
	// conf := ctx.Value(itypes.ConfigKey).(config.TomlMap)
	roomId := ctx.Value(itypes.RoomsId).(int64)
	name := ctx.Value(itypes.UserName).(string)
	userId := ctx.Value(itypes.UserId).(int64)
	return func(rw http.ResponseWriter, r *http.Request, p httprouter.Params) {
		unsafeConn, err := upgrader.Upgrade(rw, r, nil)
		if err != nil {
			log.Println("upgrade:", err)
			return
		}
		// webrtc peer
		// Create new PeerConnection
		peerConnection, err := webrtc.NewPeerConnection(peerConfig)
		if err != nil {
			log.Print(err)
			return
		}

		// When this frame returns close the PeerConnection
		defer peerConnection.Close() //nolint

		c := rooms.NewSfuConn(unsafeConn, roomId, userId, name, "", peerConnection)
		// When this frame returns close the Websocket
		// defer c.Close() //nolint
		defer c.LeaveRoom()
		room := c.JoinRoom()
		if room.CheckRoomTimeIsZero() {
			// 初始化房间过期时间
			db := meetingDb.New(db)
			roomRow, err := db.SelectRoomInfoByNo(ctx, roomId)
			if err != nil {
				log.Println(err)
			} else {
				room.SetEndTime(roomRow.EndTime.Time)
			}
		}
		// Accept one audio and one video track incoming
		for _, typ := range []webrtc.RTPCodecType{webrtc.RTPCodecTypeVideo, webrtc.RTPCodecTypeAudio} {
			if _, err := peerConnection.AddTransceiverFromKind(typ, webrtc.RTPTransceiverInit{
				Direction: webrtc.RTPTransceiverDirectionRecvonly,
			}); err != nil {
				log.Print(err)
				return
			}
		}

		// peerConnection.OnNegotiationNeeded(func() {
		// 	log.Println("OnNegotiationNeeded")
		// })

		// Trickle ICE. Emit server candidate to client
		peerConnection.OnICECandidate(func(i *webrtc.ICECandidate) {
			if i == nil {
				return
			}

			candidateString, err := json.Marshal(i.ToJSON())
			if err != nil {
				log.Println(err)
				return
			}

			if writeErr := c.WriteJSON(&websocketMessage{
				Event: "candidate",
				Data:  string(candidateString),
			}); writeErr != nil {
				log.Println(writeErr)
			}
		})

		// If PeerConnection is closed remove it from global list
		peerConnection.OnConnectionStateChange(func(p webrtc.PeerConnectionState) {
			switch p {
			case webrtc.PeerConnectionStateFailed:
				if err := peerConnection.Close(); err != nil {
					log.Print(err)
				}
			case webrtc.PeerConnectionStateClosed:
				room.SignalPeerConnections()
			case webrtc.PeerConnectionStateConnected:
				room.SignalPeerConnections()
			}
		})

		peerConnection.OnTrack(func(t *webrtc.TrackRemote, r *webrtc.RTPReceiver) {
			log.Printf("RoomId:%d\tUserId:%d\tStreamId:%s\r\n", roomId, userId, r.Track().StreamID())
			// Create a track to fan out our incoming video to all peers
			trackLocal := room.AddTrack(t)
			defer room.RemoveTrack(trackLocal)
			buf := make([]byte, 1500)
			for {
				i, _, err := t.Read(buf)
				if err != nil {
					return
				}

				if _, err = trackLocal.Write(buf[:i]); err != nil {
					return
				}
			}
		})
		// webrtc peer

		msg := userEvent{Uid: userId, Name: name}
		data, err := json.Marshal(msg)
		if err != nil {
			log.Println(err)
			return
		}
		// 用户通过认证,对该用户下发个人信息
		if err := c.WriteJSON(&websocketMessage{
			Event: "sync",
			Data:  string(data),
		}); err != nil {
			log.Println(err)
			return
		}
		// 用户加入房间，对房间内用户进行广播
		room.Broadcast(&websocketMessage{
			Event: "join",
			Data:  string(data),
		})
		// 用户加入房间，同步更早加入房间的用户给新用户

		// 开启心跳
		go func() {
			timer := time.NewTicker(time.Second * 10)
			defer timer.Stop()
			var err error
			for range timer.C {
				err = c.WriteJSON(&websocketMessage{Event: "ping"})
				if err != nil {
					event := userEvent{Uid: userId}
					msg, err := json.Marshal(event)
					if err != nil {
						log.Println(err)
					}
					room.Broadcast(&websocketMessage{
						Event: "leave",
						Data:  util.BytesToString(msg),
					})
					return
				}
			}
		}()
		// test
		// 用户加入则下发offer，用于同步当前房间已存在的流信息
		room.SignalPeerConnections()
		message := &websocketMessage{}
		for {
			_, raw, err := c.ReadMessage()
			if err != nil {
				log.Println(err)
				return
			} else if err := json.Unmarshal(raw, &message); err != nil {
				log.Println(err)
				return
			}

			switch message.Event {
			case "set_stream":
				// 用户流id更新事件
				// streamId := message.Data
				// room.Broadcast(msg interface{})
				//  房间广播用户流更新
				// 校验数据格式
				event := userEvent{}
				if err := json.Unmarshal([]byte(message.Data), &event); err != nil {
					log.Println(err)
					return
				}
				c.SetStreamId(event.StreamID)
				// 用户加入事件
				room.Broadcast(&websocketMessage{
					Event: message.Event,
					Data:  message.Data,
				})
			case "leave":
				// 用户离开事件
				event := userEvent{Uid: userId}
				msg, err := json.Marshal(event)
				if err != nil {
					log.Println(err)
				}
				room.Broadcast(&websocketMessage{
					Event: message.Event,
					Data:  util.BytesToString(msg),
				})
				return
			case "candidate":
				candidate := webrtc.ICECandidateInit{}
				if err := json.Unmarshal([]byte(message.Data), &candidate); err != nil {
					log.Println(err)
					return
				}

				if err := peerConnection.AddICECandidate(candidate); err != nil {
					log.Println(err)
					return
				}
			case "answer":
				answer := webrtc.SessionDescription{}
				if err := json.Unmarshal([]byte(message.Data), &answer); err != nil {
					log.Println(err)
					return
				}

				if err := peerConnection.SetRemoteDescription(answer); err != nil {
					log.Println(err)
					return
				}
			case "Renegotiation":
				// 客户端主动触发重新协商事件
				room.SignalPeerConnections()
			}
		}
	}
}
