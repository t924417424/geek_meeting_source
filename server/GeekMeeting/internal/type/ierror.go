package itypes

type StatusCode int

var (
	NoError            = NewError(200, "ok")
	EmailErr           = NewError(4016, "邮箱格式错误")
	LimitErr           = NewError(4017, "操作频繁")
	MarshalErr         = NewError(5011, "数据序列化错误")
	UnKnowError        = NewError(5010, "")
	SendEmaiError      = NewError(5011, "发送邮件失败")
	InternalError      = NewError(5101, "内部错误，请联系开发者")
	VerifyFormErr      = NewError(5012, "验证码错误")
	VerificationFailed = NewError(5013, "验证不通过")
	CreateUserErr      = NewError(5014, "创建用户失败")
	ReLoginUser        = NewError(5015, "服务端错误，请重新登陆")
	TimerErr           = NewError(5016, "时间参数错误")
	CreateRoomErr      = NewError(5017, "创建房间错误")
	RoomIdErr          = NewError(5018, "房间号或密码错误")
	MeetingDidNotStart = NewError(5019, "会议未开始（可提前五分钟入场）")
	MeetingEnded       = NewError(5020, "会议已结束")
	CacheRoomInfoErr   = NewError(5021, "加入房间失败")
)

type myError struct {
	code int
	info string
}

func (e myError) Error() string {

	return e.info
}

func NewError(code int, info string) myError {
	return myError{
		code,
		info,
	}
}

func ErrIntoMyError(e error) myError {
	return myError{
		UnKnowError.code,
		e.Error(),
	}
}

func (e myError) ToResp() resp {
	return resp{
		Code: e.code,
		Msg:  e.info,
	}
}
