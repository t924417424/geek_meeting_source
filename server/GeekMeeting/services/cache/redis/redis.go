package redis

import (
	"GeekMeeting/internal/config"
	itypes "GeekMeeting/internal/type"
	"GeekMeeting/services/cache"
	"context"
	"sync"
	"time"

	"github.com/go-redis/redis/v8"
)

type redisWrap struct {
	client *redis.Client
}

var (
	once    sync.Once
	cacheDb redisWrap
)

func GetRedis(ctx context.Context) cache.Cache {
	once.Do(func() {
		conf := ctx.Value(itypes.ConfigKey).(config.TomlMap)
		cacheDb = redisWrap{
			redis.NewClient(&redis.Options{
				Addr:        conf.SQL.Cache.Addr,
				Username:    conf.SQL.Cache.Username,
				Password:    conf.SQL.Cache.Password,
				DialTimeout: time.Second * 3,
			}),
		}
	})
	return cacheDb
}

func (c redisWrap) Set(ctx context.Context, key string, value interface{}) error {
	return c.client.Set(ctx, key, value, 0).Err()
}

func (c redisWrap) Get(ctx context.Context, key string) ([]byte, error) {
	return c.client.Get(ctx, key).Bytes()
}

func (c redisWrap) SetEx(ctx context.Context, key string, value interface{}, expiration time.Duration) error {
	return c.client.SetEX(ctx, key, value, expiration).Err()
}

func (c redisWrap) IsExist(ctx context.Context, key string) bool {
	var flag bool
	if result := c.client.Exists(ctx, key); result.Err() == nil {
		// log.Println(result.Val())
		if result.Val() > 0 {
			flag = true
		}
	}
	return flag
}

func (c redisWrap) DelKey(ctx context.Context, key string) error {
	return c.client.Del(ctx, key).Err()
}
