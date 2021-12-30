package meeting

import (
	"GeekMeeting/internal/config"
	itypes "GeekMeeting/internal/type"
	"context"
	"database/sql"
	"sync"

	_ "github.com/go-sql-driver/mysql"
)

var (
	sqlOnce sync.Once
	sqlDb   *sql.DB
)

func GetMysql(ctx context.Context) (db *sql.DB, err error) {
	sqlOnce.Do(func() {
		conf := ctx.Value(itypes.ConfigKey).(config.TomlMap)
		sqlDb, err = sql.Open(conf.SQL.Databases.Driver, conf.SQL.Databases.Dsn)
		if err != nil {
			panic(err)
		}
	})
	return sqlDb, err
}
