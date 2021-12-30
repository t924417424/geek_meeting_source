package rooms

import (
	"sync"

	"github.com/gorilla/websocket"
	"github.com/pion/webrtc/v3"
)

type websocketMessage struct {
	Event string `json:"event"`
	Data  string `json:"data"`
}

// Helper to make Gorilla Websockets threadsafe
type threadSafeWriter struct {
	*websocket.Conn
	sync.Mutex
	roomId         int64
	uid            int64
	name           string
	streamId       string
	peerConnection *webrtc.PeerConnection
}

func NewSfuConn(conn *websocket.Conn, roomId, uid int64, name, streamId string, peer *webrtc.PeerConnection) *threadSafeWriter {
	return &threadSafeWriter{conn, sync.Mutex{}, roomId, uid, name, streamId, peer}
}

func (t *threadSafeWriter) SetStreamId(streamId string) {
	t.streamId = streamId
}

func (t *threadSafeWriter) WriteJSON(v interface{}) error {
	t.Lock()
	defer t.Unlock()

	return t.Conn.WriteJSON(v)
}

func (t *threadSafeWriter) JoinRoom() *room {
	return getRooms().joinRoom(t.roomId, t)
}

// func (t *threadSafeWriter) CheckRoomTime() bool {
// 	return getRooms().checkRoomTime(t.roomId)
// }

func (t *threadSafeWriter) LeaveRoom() {
	t.Conn.Close()
	// t.exit <- struct{}{}
	getRooms().leaveRoom(t.roomId, t)
}
