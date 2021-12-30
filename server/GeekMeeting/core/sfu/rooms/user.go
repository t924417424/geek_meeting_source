package rooms

type UserEvent struct {
	Uid      int64  `json:"uid"`
	StreamID string `json:"streamId"`
	Name     string `json:"name"`
}
