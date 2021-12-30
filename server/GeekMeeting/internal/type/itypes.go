package itypes

import "encoding/json"

type contextKey int

const (
	TimeFormat              = "2006-01-02 15:04:05"
	DatabasesKey contextKey = iota
	CacheKey
	ConfigKey
	UserId
	JwtKey
	Rooms
	RoomsId
	UserName
)

// type Middleware

type JoinInfo struct {
	RoomId   int64
	UserId   int64
	UserName string
}

type resp struct {
	Code  int         `json:"code"`
	Msg   string      `json:"msg"`
	Data  interface{} `json:"data"`
	Token struct {
		AccessToken  string `json:"access_token"`
		RefreshToken string `json:"refresh_token"`
	} `json:"token"`
}

func NewResp() resp {
	return resp{}
}

func (r resp) ToJson() ([]byte, error) {
	b, err := json.Marshal(r)
	if err != nil {
		return nil, MarshalErr
	}
	return b, nil
}
