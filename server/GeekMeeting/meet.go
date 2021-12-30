package main

import (
	"GeekMeeting/api/router"
	"GeekMeeting/internal/config"
	itypes "GeekMeeting/internal/type"
	"GeekMeeting/internal/util"
	"GeekMeeting/services/cache/redis"
	meeting "GeekMeeting/services/database/mysql"
	"context"
	"flag"
	"log"
	"net/http"
	_ "net/http/pprof"

	_ "github.com/go-sql-driver/mysql"
	"github.com/julienschmidt/httprouter"
	"github.com/rs/cors"
)

func main() {
	var configPath string
	flag.StringVar(&configPath, "config", "./config.toml", "自定义配置文件")
	flag.Parse()
	log.SetFlags(log.Lshortfile | log.Ldate | log.Ltime)
	ctx := context.Background()
	conf := config.GetConf(configPath)
	ctx = context.WithValue(ctx, itypes.ConfigKey, conf)

	db, err := meeting.GetMysql(ctx)
	if err != nil {
		panic(err)
	}
	defer db.Close()
	cacheDb := redis.GetRedis(ctx)
	jwt := util.NewJwt(util.StringToBytes(conf.Server.Web.JwtKey))
	ctx = context.WithValue(ctx, itypes.JwtKey, jwt)
	ctx = context.WithValue(ctx, itypes.DatabasesKey, db)
	ctx = context.WithValue(ctx, itypes.CacheKey, cacheDb)
	r := httprouter.New()
	router.InitRouter(r, ctx)
	// handler := cors.Default().Handler(r)
	handler := cors.AllowAll().Handler(r)
	log.Printf("server run on %s\r\n", conf.Server.Web.Addr)
	if err := http.ListenAndServe(conf.Server.Web.Addr, handler); err != nil {
		log.Fatal(err)
	}
}
