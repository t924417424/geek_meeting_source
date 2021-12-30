package config

import (
	"log"
	"os"
	"sync"

	"github.com/BurntSushi/toml"
)

var (
	config   TomlMap
	confOnce sync.Once
)

type TomlMap struct {
	Server struct {
		Web struct {
			Addr       string `toml:"addr"`
			JwtKey     string `toml:"jwtKey"`
			MaxTime    int64  `toml:"maxTime"`
			RoomLimit  int64  `toml:"roomLimit"`
			RoomPeople int    `toml:"roomPeople"`
		} `toml:"web"`
	} `toml:"server"`
	SQL struct {
		Databases struct {
			Driver string `toml:"driver"`
			Dsn    string `toml:"dsn"`
		} `toml:"databases"`
		Cache struct {
			Addr     string `toml:"addr"`
			Username string `toml:"username"`
			Password string `toml:"password"`
		} `toml:"cache"`
	} `toml:"sql"`
	Mail struct {
		Server   string `toml:"server"`
		Port     int    `toml:"port"`
		Name     string `toml:"name"`
		Username string `toml:"username"`
		Password string `toml:"password"`
	} `toml:"mail"`
}

func GetConf(path string) TomlMap {
	confOnce.Do(func() {
		_, err := toml.DecodeFile(path, &config)
		if err != nil {
			log.Fatalf("%v", err)
			os.Exit(1)
		}
	})
	return config
}
