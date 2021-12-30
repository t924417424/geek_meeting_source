package middleware

import (
	itypes "GeekMeeting/internal/type"
	"GeekMeeting/internal/util"
	"GeekMeeting/services/auth"
	"GeekMeeting/services/cache"
	"context"
	"log"
	"net/http"
	"strings"

	"github.com/julienschmidt/httprouter"
)

func AuthMiddleware(ctx context.Context, next func(context.Context) httprouter.Handle) httprouter.Handle {
	jwt := ctx.Value(itypes.JwtKey).(auth.JwtTool)
	return func(rw http.ResponseWriter, r *http.Request, p httprouter.Params) {
		authorization := r.Header.Get("Authorization")
		// log.Println(authorization)
		if !strings.HasPrefix(authorization, "Bearer ") {
			rw.WriteHeader(http.StatusUnauthorized)
			return
		}
		authorization = authorization[7:]
		uid, state, err := jwt.ParseToken(authorization)
		if err != nil || !state {
			rw.WriteHeader(http.StatusUnauthorized)
			return
		}
		ctx = context.WithValue(ctx, itypes.UserId, uid)
		// r = r.WithContext(ctx)
		next(ctx)(rw, r, p)
	}
}

func AuthMiddlewareSignal(ctx context.Context, next func(context.Context) httprouter.Handle) httprouter.Handle {
	// jwt := ctx.Value(itypes.JwtKey).(auth.JwtTool)
	// db := ctx.Value(itypes.DatabasesKey).(*sql.DB)
	// roomDb := meetingDb.New(db)
	cache := ctx.Value(itypes.CacheKey).(cache.Cache)
	return func(rw http.ResponseWriter, r *http.Request, p httprouter.Params) {
		key := p.ByName("key")
		// uid, state, err := jwt.ParseToken(authorization)
		// if err != nil || !state {
		// 	log.Println(err, state)
		// 	rw.WriteHeader(http.StatusUnauthorized)
		// 	return
		// }
		// roomIdStr := p.ByName("room_id")
		// name := p.ByName("name")
		// password := p.ByName("password")
		// if password != "" {
		// 	password = util.Md5(password)
		// }
		// roomId, _ := strconv.ParseInt(roomIdStr, 10, 64)
		// if roomId <= 0 || name == "" {
		// 	log.Println(err, state)
		// 	rw.WriteHeader(http.StatusBadRequest)
		// 	return
		// }
		// // 校验会议ID和密码
		// roomInfo, err := roomDb.SelectRoomInfoByIdAndPassword(ctx,
		// 	meetingDb.SelectRoomInfoByIdAndPasswordParams{
		// 		ID:       int64(roomId),
		// 		Password: password,
		// 	},
		// )
		// if err != nil {
		// 	resp, err := itypes.RoomIdErr.ToResp().ToJson()
		// 	if err != nil {
		// 		log.Println(err)
		// 		rw.WriteHeader(http.StatusBadGateway)
		// 		return
		// 	}
		// 	_, _ = rw.Write(resp)
		// 	return
		// }
		// // 校验会议开始和结束时间
		// currentTime := time.Now()
		// if roomInfo.StartTime.Time.After(currentTime.Add(time.Minute*5)) || roomInfo.EndTime.Time.Before(currentTime) {
		// 	resp, err := itypes.MeetingDidNotStart.ToResp().ToJson()
		// 	if err != nil {
		// 		log.Println(err)
		// 		rw.WriteHeader(http.StatusBadGateway)
		// 		return
		// 	}
		// 	_, _ = rw.Write(resp)
		// 	return
		// }
		if key == "" {
			rw.WriteHeader(http.StatusUnauthorized)
			return
		}
		joinInfoBytes, err := cache.Get(ctx, key)
		if err != nil {
			log.Println(err)
			rw.WriteHeader(http.StatusServiceUnavailable)
		}
		var joinInfo itypes.JoinInfo
		if err := util.NewCoding(util.Gob).Decode(joinInfoBytes, &joinInfo); err != nil {
			log.Println(err)
			rw.WriteHeader(http.StatusServiceUnavailable)
		}
		if err := cache.DelKey(ctx, key); err != nil {
			log.Println(err)
		}
		ctx = context.WithValue(ctx, itypes.UserId, joinInfo.UserId)
		ctx = context.WithValue(ctx, itypes.RoomsId, joinInfo.RoomId)
		ctx = context.WithValue(ctx, itypes.UserName, joinInfo.UserName)
		next(ctx)(rw, r, p)
	}
}
