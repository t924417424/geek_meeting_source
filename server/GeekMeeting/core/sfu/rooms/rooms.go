package rooms

import (
	"log"
	"sync"
	"time"

	"github.com/pion/webrtc/v3"
)

var (
	roomsOnce sync.Once
	rms       *rooms
)

type rooms struct {
	sync.Locker
	rs map[int64]*room
}

func GetNumber(roomId int64) (count int) {
	if _, ok := getRooms().rs[roomId]; ok {
		count = len(getRooms().rs[roomId].peerConnections)
	}
	return
}

func getRooms() *rooms {
	roomsOnce.Do(func() {
		rms = &rooms{&sync.Mutex{}, map[int64]*room{}}
		// 无效房间自动回收
		go rms.free()
	})
	return rms
}

// func (r *rooms) checkRoomTime(roomId int64) bool {
// 	_, result := r.rs[roomId]
// 	if result {
// 		result = r.rs[roomId].exitTime.IsZero()
// 	}
// 	return result
// }

func (r *rooms) joinRoom(roomId int64, user *threadSafeWriter) (roomPtr *room) {
	var ok bool
	if roomPtr, ok = r.rs[roomId]; !ok {
		r.Lock()
		defer r.Unlock()
		roomPtr = &room{trackLocals: make(map[string]*webrtc.TrackLocalStaticRTP), free: make(chan struct{})}
		roomPtr.init()
		r.rs[roomId] = roomPtr
		// 定时发送关键帧
		// 房间到期关闭
		// go func() {
		// 	timer := time.NewTimer(time.Second * 30)
		// 	for {
		// 		select {
		// 		case <-timer.C:
		// 			if time.Now().After(endTIime) {
		// 				r.closeRoom(roomId)
		// 				return
		// 			}
		// 		}
		// 	}
		// }()
	}
	roomPtr.userJoin(user)
	// log.Printf("%#v", user)
	// log.Println(r.rs[roomId])
	// log.Println(roomPtr)
	return roomPtr
}

// 关闭房间
// func (r *rooms) closeRoom(roomId int64) {
// 	if roomPtr, ok := r.rs[roomId]; ok {
// 		roomPtr.RLock()
// 		for index := range roomPtr.peerConnections {
// 			_ = roomPtr.peerConnections[index].user.Close()
// 		}
// 		roomPtr.RUnlock()
// 		roomPtr.free <- struct{}{}
// 		r.Lock()
// 		delete(r.rs, roomId)
// 		r.Unlock()
// 	}
// }

// 用户离开房间
func (r *rooms) leaveRoom(roomId int64, user *threadSafeWriter) {
	if roomPtr, ok := r.rs[roomId]; ok {
		roomPtr.Lock()
		defer roomPtr.Unlock()
		for index := range roomPtr.peerConnections {
			if roomPtr.peerConnections[index].user == user {
				roomPtr.peerConnections = append(roomPtr.peerConnections[0:index], roomPtr.peerConnections[index+1:]...)
				// log.Println("leave room:", len(roomPtr.peerConnections))
				if len(roomPtr.peerConnections) == 0 {
					r.Lock()
					delete(r.rs, roomId)
					r.Unlock()
					log.Printf("free room %d\r\n", roomId)
				}
				return
			}
		}
	}
}

func (r *rooms) free() {
	timer := time.NewTicker(time.Minute * 10)
	defer timer.Stop()
	var waitRemove = make([]int64, 0, 10)
	for range timer.C {
		freeTime := time.Now().Add(time.Minute * -3)
		for index := range r.rs {
			// 如果房间已超过资源自身回收周期，则从map中移除
			if !r.rs[index].exitTime.IsZero() && r.rs[index].exitTime.Before(freeTime) {
				waitRemove = append(waitRemove, index)
			}
		}
		r.Lock()
		for index := range waitRemove {
			delete(r.rs, waitRemove[index])
		}
		r.Unlock()
		waitRemove = waitRemove[0:0]
	}
}
