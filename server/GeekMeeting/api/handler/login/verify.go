package login

import (
	my_types "GeekMeeting/internal/type"
	"GeekMeeting/internal/util"
	"GeekMeeting/services/auth"
	"GeekMeeting/services/cache"
	meetingDb "GeekMeeting/services/database/mysql/meeting"
	"context"
	"database/sql"
	"log"
	"net/http"
	"strings"

	"github.com/julienschmidt/httprouter"
)

// 验证校验码
func Verify(ctx context.Context) httprouter.Handle {
	cache := ctx.Value(my_types.CacheKey).(cache.Cache)
	jwt := ctx.Value(my_types.JwtKey).(auth.JwtTool)
	db := ctx.Value(my_types.DatabasesKey).(*sql.DB)
	users := meetingDb.New(db)
	return func(rw http.ResponseWriter, r *http.Request, p httprouter.Params) {
		vCode := r.FormValue("verify_code")
		eMail := r.FormValue("email")
		clientIp := strings.Split(r.RemoteAddr, ":")[0]
		cacheMailByte, err := cache.Get(ctx, clientIp)
		cacheMail := util.BytesToString(cacheMailByte)
		if vCode == "" || err != nil || cacheMail == "" {
			resp, err := my_types.VerifyFormErr.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		// 验证邮箱和验证码是否通过
		cacheVerifyCodeByte, err := cache.Get(ctx, cacheMail)
		cacheVerifyCode := util.BytesToString(cacheVerifyCodeByte)
		if eMail != cacheMail || err != nil || cacheVerifyCode != vCode {
			resp, err := my_types.VerificationFailed.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		_ = cache.DelKey(ctx, clientIp)
		_ = cache.DelKey(ctx, eMail)
		// log.Println(eMail)
		// 检查用户是否存在
		id, err := users.FindUserByEmail(ctx, eMail)
		if err != nil && err != sql.ErrNoRows {
			log.Println(err)
			resp, err := my_types.InternalError.ToResp().ToJson()
			if err != nil {
				log.Println(err)
				rw.WriteHeader(http.StatusBadGateway)
				return
			}
			_, _ = rw.Write(resp)
			return
		}
		// 用户不存在，创建用户
		if id == 0 {
			if result, err := users.CreateUser(ctx, eMail); err != nil {
				resp, err := my_types.CreateUserErr.ToResp().ToJson()
				if err != nil {
					log.Println(err)
					rw.WriteHeader(http.StatusBadGateway)
					return
				}
				_, _ = rw.Write(resp)
				return
			} else {
				id, err = result.LastInsertId()
				if err != nil {
					resp, err := my_types.ReLoginUser.ToResp().ToJson()
					if err != nil {
						log.Println(err)
						rw.WriteHeader(http.StatusBadGateway)
						return
					}
					_, _ = rw.Write(resp)
					return
				}
			}
		}
		// log.Println("create token")
		// create token
		rsp := my_types.NoError.ToResp()
		// rsp.Token.AccessToken
		accessToken, refreshToken, err := jwt.NewToken(id)
		if err != nil {
			log.Println("NewToken:", err)
			rw.WriteHeader(http.StatusBadGateway)
			return
		}
		rsp.Token.AccessToken = accessToken
		rsp.Token.RefreshToken = refreshToken
		resp, err := rsp.ToJson()
		if err != nil {
			log.Println(err)
			rw.WriteHeader(http.StatusBadGateway)
			return
		}
		_, _ = rw.Write(resp)
	}
}
