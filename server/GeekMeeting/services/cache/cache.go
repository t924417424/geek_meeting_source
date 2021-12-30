package cache

import (
	"context"
	"time"
)

type Cache interface {
	Set(ctx context.Context, key string, value interface{}) error
	Get(ctx context.Context, key string) ([]byte, error)
	SetEx(ctx context.Context, key string, value interface{}, expiration time.Duration) error
	IsExist(ctx context.Context, key string) bool
	DelKey(ctx context.Context, key string) error
}
