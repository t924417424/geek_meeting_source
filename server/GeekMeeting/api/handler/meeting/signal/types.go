package signal

import (
	"GeekMeeting/core/sfu/rooms"
	"net/http"

	"github.com/gorilla/websocket"
	"github.com/pion/webrtc/v3"
)

var (
	upgrader = websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool { return true },
	}
)

type websocketMessage struct {
	Event string `json:"event"`
	Data  string `json:"data"`
}

type userEvent rooms.UserEvent

var peerConfig = webrtc.Configuration{
	ICEServers: []webrtc.ICEServer{
		{
			URLs: []string{"stun:stun.l.google.com:19302"},
		},
	},
}