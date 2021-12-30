package router

import (
	"GeekMeeting/api/handler/login"
	"GeekMeeting/api/handler/meeting"
	"GeekMeeting/api/handler/meeting/signal"
	"GeekMeeting/api/handler/token"
	"GeekMeeting/api/middleware"
	"context"
	"net/http"

	"github.com/julienschmidt/httprouter"
)

//  初始化Router
func InitRouter(router *httprouter.Router, ctx context.Context) {
	router.PanicHandler = middleware.PaincHandle
	router.Handler(http.MethodGet, "/debug/pprof/*item", http.DefaultServeMux)
	router.POST("/send", login.SendCode(ctx))
	router.POST("/verify", login.Verify(ctx))
	router.POST("/refresh_token", token.Refresh(ctx))
	router.POST("/create_meeting", middleware.AuthMiddleware(ctx, meeting.CreateMeeting))
	router.POST("/join_meeting", middleware.AuthMiddleware(ctx, meeting.JoinMeeting))
	router.GET("/recond", middleware.AuthMiddleware(ctx, meeting.MeetingRecord))
	router.GET("/signal/:key", middleware.AuthMiddlewareSignal(ctx, signal.SignalHandler))
}
