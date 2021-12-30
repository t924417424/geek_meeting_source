package token

import (
	itypes "GeekMeeting/internal/type"
	"GeekMeeting/services/auth"
	"context"
	"log"
	"net/http"
	"strings"

	"github.com/julienschmidt/httprouter"
)

// token刷新接口
func Refresh(ctx context.Context) httprouter.Handle {
	jwt := ctx.Value(itypes.JwtKey).(auth.JwtTool)
	return func(rw http.ResponseWriter, r *http.Request, p httprouter.Params) {
		authorization := r.Header.Get("Authorization")
		// log.Println(authorization)
		if !strings.HasPrefix(authorization, "Bearer ") {
			rw.WriteHeader(http.StatusUnauthorized)
			return
		}
		authorization = authorization[7:]
		refresh := r.FormValue("refresh_token")
		accessToken, refreshToken, err := jwt.RefreshToken(refresh, authorization)
		if err != nil {
			log.Println("NewToken:", err)
			rw.WriteHeader(http.StatusUnauthorized)
			return
		}
		rsp := itypes.NoError.ToResp()
		rsp.Token.AccessToken = accessToken
		rsp.Token.RefreshToken = refreshToken
		resp, err := rsp.ToJson()
		if err != nil {
			log.Println(err)
			rw.WriteHeader(http.StatusUnauthorized)
			return
		}
		_, _ = rw.Write(resp)
	}
}
