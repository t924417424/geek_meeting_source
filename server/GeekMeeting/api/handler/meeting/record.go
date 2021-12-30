package meeting

import (
	itypes "GeekMeeting/internal/type"
	meetingDb "GeekMeeting/services/database/mysql/meeting"
	"context"
	"database/sql"
	"log"
	"net/http"
	"strconv"

	"github.com/julienschmidt/httprouter"
)

// 用户房间记录查询
func MeetingRecord(ctx context.Context) httprouter.Handle {
	db := ctx.Value(itypes.DatabasesKey).(*sql.DB)
	// local, _ := time.LoadLocation("Asia/Shanghai")
	roomDb := meetingDb.New(db)
	return func(rw http.ResponseWriter, r *http.Request, p httprouter.Params) {
		userId := ctx.Value(itypes.UserId).(int64)
		pageStr := r.URL.Query().Get("page")
		page, err := strconv.Atoi(pageStr)
		if err != nil || page <= 0 {
			page = 1
		}
		// 查询用户房间记录
		var pageSize int32 = 10
		var offset int32 = (int32(page) - 1) * 10
		rooms, err := roomDb.SelectRecondByUserId(ctx, meetingDb.SelectRecondByUserIdParams{
			MasterID: userId,
			Offset:   offset,
			Limit:    pageSize,
		})
		if err != nil && err != sql.ErrNoRows {
			resp, err := itypes.UnKnowError.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		// 返回用户房间记录
		rsp := itypes.NoError.ToResp()
		rsp.Data = rooms
		resp, err := rsp.ToJson()
		if err != nil {
			log.Println(err)
			rw.WriteHeader(http.StatusBadGateway)
			return
		}
		_, _ = rw.Write(resp)
	}
}
