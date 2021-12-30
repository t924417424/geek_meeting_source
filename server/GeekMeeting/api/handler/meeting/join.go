package meeting

import (
	"GeekMeeting/core/sfu/rooms"
	"GeekMeeting/internal/config"
	itypes "GeekMeeting/internal/type"
	"GeekMeeting/internal/util"
	"GeekMeeting/services/cache"
	meetingDb "GeekMeeting/services/database/mysql/meeting"
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/julienschmidt/httprouter"
)

// 加入会议房间
func JoinMeeting(ctx context.Context) httprouter.Handle {
	db := ctx.Value(itypes.DatabasesKey).(*sql.DB)
	// local, _ := time.LoadLocation("Asia/Shanghai")
	conf := ctx.Value(itypes.ConfigKey).(config.TomlMap)
	cache := ctx.Value(itypes.CacheKey).(cache.Cache)
	roomDb := meetingDb.New(db)
	return func(rw http.ResponseWriter, r *http.Request, p httprouter.Params) {
		userId := ctx.Value(itypes.UserId).(int64)
		nameStr := r.PostFormValue("name")
		roomIdStr := r.PostFormValue("room_id")
		password := r.PostFormValue("password")
		if password != "" {
			password = util.Md5(password)
		}
		roomId, err := strconv.ParseInt(roomIdStr, 10, 64)
		// log.Println(roomIdStr, "=", roomId)
		if err != nil {
			// log.Println(err)
			resp, err := itypes.RoomIdErr.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		// 校验会议ID和密码
		roomInfo, err := roomDb.SelectRoomInfoByIdAndPassword(ctx,
			meetingDb.SelectRoomInfoByIdAndPasswordParams{
				ID:       int64(roomId),
				Password: password,
			},
		)
		if err != nil {
			// log.Println(err)
			resp, err := itypes.RoomIdErr.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		// 校验会议开始&结束时间
		currentTime := time.Now()
		//roomInfo.StartTime.Time.After(currentTime.Add(time.Minute*5)) ||
		if roomInfo.EndTime.Time.Before(currentTime) {
			resp, err := itypes.MeetingEnded.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		// 如果会议再当前时间的后五分钟之后则提示暂未开始，否则就允许提前或中途进入房间
		if roomInfo.StartTime.Time.After(currentTime.Add(time.Minute * 5)) {
			resp, err := itypes.MeetingDidNotStart.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		// 检测会议人数是否超限
		if rooms.GetNumber(roomId) >= conf.Server.Web.RoomPeople {
			info := fmt.Sprintf("会议最大人数不能超过%d分钟！", conf.Server.Web.RoomPeople)
			resp, err := itypes.ErrIntoMyError(errors.New(info)).ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		// 将暂存信息写入Redis，用于建立信令服务器的标识
		joinInfo := itypes.JoinInfo{
			RoomId:   roomInfo.ID,
			UserId:   userId,
			UserName: nameStr,
		}
		joinInfoByte, err := util.NewCoding(util.Gob).Encode(joinInfo)
		if err != nil {
			resp, err := itypes.InternalError.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		key := fmt.Sprintf("Meeting-%d-%d-%s", roomId, userId, util.Md5FromBytes(joinInfoByte))
		if err := cache.SetEx(ctx, key, joinInfoByte, time.Second*10); err != nil {
			log.Println(err)
			resp, err := itypes.CacheRoomInfoErr.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		// 加入会议写入会议记录
		if err := roomDb.InsertRecond(ctx, meetingDb.InsertRecondParams{
			UserID: userId,
			Name:   sql.NullString{String: nameStr, Valid: true},
			RoomID: roomInfo.ID,
		}); err != nil {
			log.Println("InsertRecond Error:", err)
		}

		// 返回会议室信息
		roomInfo.Expand = key
		rsp := itypes.NoError.ToResp()
		rsp.Data = roomInfo
		resp, err := rsp.ToJson()
		if err != nil {
			log.Println(err)
			rw.WriteHeader(http.StatusBadGateway)
			return
		}
		_, _ = rw.Write(resp)
	}
}
