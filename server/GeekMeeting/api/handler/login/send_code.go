package login

import (
	my_types "GeekMeeting/internal/type"
	"GeekMeeting/internal/util"
	"GeekMeeting/services/cache"
	"context"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"strings"
	"time"

	"github.com/julienschmidt/httprouter"
)

// 发送验证码
func SendCode(ctx context.Context) httprouter.Handle {
	// 前置检查
	rand.Seed(time.Now().UnixMicro())
	min := 1000
	max := 9999
	cache := ctx.Value(my_types.CacheKey).(cache.Cache)
	return func(rw http.ResponseWriter, r *http.Request, _ httprouter.Params) {
		clientIp := strings.Split(r.RemoteAddr, ":")[0]
		emil := r.PostFormValue("email")
		// 验证邮箱地址
		if !util.VerifyMail(emil) {
			resp, err := my_types.EmailErr.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		// 检测时候发送过于频繁
		if cache.IsExist(ctx, clientIp) || cache.IsExist(ctx, emil) {
			resp, err := my_types.LimitErr.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}

		if err := cache.SetEx(ctx, clientIp, emil, time.Minute*2); err != nil {
			resp, err := my_types.InternalError.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}

		vCode := rand.Intn(max-min) + min
		// 发送邮件
		if err := util.SendEmailTo(ctx, "GeekMeeting #", emil, fmt.Sprintf("您的验证码为：%d", vCode)); err != nil {
			resp, err := my_types.SendEmaiError.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}

		if err := cache.SetEx(ctx, emil, vCode, time.Minute*2); err != nil {
			resp, err := my_types.ErrIntoMyError(err).ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		resp, err := my_types.NoError.ToResp().ToJson()
		if err != nil {
			log.Println(err)
			rw.WriteHeader(http.StatusBadGateway)
			return
		}
		_, _ = rw.Write(resp)
	}
}
