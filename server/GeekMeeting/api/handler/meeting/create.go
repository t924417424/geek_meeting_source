package meeting

import (
	"GeekMeeting/internal/config"
	"GeekMeeting/internal/sqltime"
	itypes "GeekMeeting/internal/type"
	"GeekMeeting/internal/util"
	meetingDb "GeekMeeting/services/database/mysql/meeting"
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/julienschmidt/httprouter"
)

// 创建会议房间
func CreateMeeting(ctx context.Context) httprouter.Handle {
	db := ctx.Value(itypes.DatabasesKey).(*sql.DB)
	local, _ := time.LoadLocation("Asia/Shanghai")
	conf := ctx.Value(itypes.ConfigKey).(config.TomlMap)
	roomDb := meetingDb.New(db)
	return func(rw http.ResponseWriter, r *http.Request, p httprouter.Params) {
		var MasterID int64 = ctx.Value(itypes.UserId).(int64)
		var startTime time.Time
		var endTime time.Time
		startTimeStr := r.PostFormValue("start_time")
		endTimeStr := r.PostFormValue("end_time")
		password := r.PostFormValue("password")
		if password != "" {
			password = util.Md5(password)
		}
		year, month, day := time.Now().Date()
		nyear, nmonth, nday := time.Now().AddDate(0, 0, 1).Date()
		count, err := roomDb.RoomInDayCount(ctx, meetingDb.RoomInDayCountParams{
			MasterID:     MasterID,
			CreateTime:   sqltime.NullTime{Time: time.Date(year, month, day, 0, 0, 0, 0, local), Valid: true},
			CreateTime_2: sqltime.NullTime{Time: time.Date(nyear, nmonth, nday, 0, 0, 0, 0, local), Valid: true},
		})
		if err != nil {
			resp, err := itypes.UnKnowError.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		if count >= conf.Server.Web.RoomLimit {
			resp, err := itypes.ErrIntoMyError(errors.New("超出每日可创建房间数的最大限制！")).ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		startTime, err1 := time.ParseInLocation(itypes.TimeFormat, startTimeStr, local)
		endTime, err2 := time.ParseInLocation(itypes.TimeFormat, endTimeStr, local)
		if err1 != nil || err2 != nil {
			resp, err := itypes.TimerErr.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		// 校验创建会议的开始时间不能小于当前时间，且最大时常不能大于 conf.Server.Web.MaxTime
		diffTime := endTime.Sub(startTime)
		if diffTime.Minutes() < 0 || diffTime.Minutes() > float64(conf.Server.Web.MaxTime) {
			info := fmt.Sprintf("会议最大时长不能超过%d分钟！", conf.Server.Web.MaxTime)
			resp, err := itypes.ErrIntoMyError(errors.New(info)).ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		// 会议房间信息写入sql
		result, err := roomDb.CreateRoom(
			ctx,
			meetingDb.CreateRoomParams{
				StartTime: sqltime.NullTime{
					Time:  startTime,
					Valid: true,
				},
				EndTime: sqltime.NullTime{
					Time:  endTime,
					Valid: true,
				},
				Password: password,
				MasterID: MasterID,
			},
		)
		if err != nil {
			resp, err := itypes.CreateRoomErr.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		res := itypes.NoError.ToResp()
		RoomID, _ := result.LastInsertId()
		res.Data = struct {
			RoomId    int64  `json:"room_id"`
			StartTime string `json:"start_time"`
		}{
			RoomId:    RoomID,
			StartTime: startTime.Format(itypes.TimeFormat),
		}
		resp, err := res.ToJson()
		// res.Data =
		if err != nil {
			log.Println(err)
			rw.WriteHeader(http.StatusBadGateway)
			return
		}
		_, _ = rw.Write(resp)
	}
}
