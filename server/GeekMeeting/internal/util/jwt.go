package util

import (
	"GeekMeeting/services/auth"
	"errors"
	"sync"
	"time"

	"github.com/golang-jwt/jwt"
)

type tokenType uint

var (
	jwtOnce sync.Once
	tool    *jwtTool
	access  tokenType = 0
	refresh tokenType = 1
)

type myClaims struct {
	Uid    int64     `json:"uid"`
	Type   tokenType `json:"type"`
	Rtsign string    `json:"rt_sign"`
	jwt.StandardClaims
}

type jwtTool struct {
	key []byte
}

func NewJwt(key ...[]byte) auth.JwtTool {
	jwtOnce.Do(func() {
		tool = &jwtTool{}
		tool.SetKey(key[0])
	})
	return tool
}

func (j *jwtTool) SetKey(key []byte) {
	j.key = key
}

func (j *jwtTool) GetKey() []byte {
	return j.key
}

func (j *jwtTool) NewToken(userId int64) (accessToken, refreshToken string, err error) {
	accessToken, err = newToken(myClaims{
		userId,
		access,
		"",
		jwt.StandardClaims{
			ExpiresAt: time.Now().Add(time.Minute * 10).Unix(),
		},
	}, j.GetKey())
	if err != nil {
		return "", "", err
	}
	refreshToken, err = newToken(myClaims{
		userId,
		refresh,
		Md5(accessToken),
		jwt.StandardClaims{
			ExpiresAt: time.Now().Add(time.Hour * 3 * 24).Unix(),
		},
	}, j.GetKey())
	if err != nil {
		return "", "", err
	}
	return
}

func (j *jwtTool) ParseToken(tokenStr string) (int64, bool, error) {
	var c = myClaims{}
	token, err := jwt.ParseWithClaims(tokenStr, &c, func(t *jwt.Token) (interface{}, error) {
		return j.GetKey(), nil
	})
	if err != nil || c.Type != access {
		return c.Uid, false, err
	}
	return c.Uid, token.Valid, err
}

func (j *jwtTool) RefreshToken(tokenStr, oldToken string) (accessToken, refreshToken string, err error) {
	var c = myClaims{}
	// 检查被刷新的token
	auid, astate, err := j.ParseToken(oldToken)
	if err == nil || astate {
		return "", "", errors.New("Invalid token 1")
	}
	token, err := jwt.ParseWithClaims(tokenStr, &c, func(t *jwt.Token) (interface{}, error) {
		return j.GetKey(), nil
	})
	if err != nil || c.Type != refresh || c.Uid != auid || c.Rtsign != Md5(oldToken) || !token.Valid {
		return "", "", errors.New("Invalid token 2")
	}
	return j.NewToken(c.Uid)
}

func newToken(c myClaims, key []byte) (string, error) {
	nToken := jwt.NewWithClaims(jwt.SigningMethodHS256, c)
	return nToken.SignedString(key)
}
