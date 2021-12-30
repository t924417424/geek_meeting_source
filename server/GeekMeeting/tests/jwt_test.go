package tests

import (
	"GeekMeeting/internal/util"
	"testing"
)

var (
	myToken       = util.NewJwt([]byte{4, 48, 64, 98, 6, 87, 1, 8, 7, 4, 84, 48})
	uid     int64 = 1
)

func TestNewJwt(t *testing.T) {
	a, r, err := myToken.NewToken(uid)
	if err != nil {
		t.Error(err)
	}
	t.Log("access_token:", a)
	t.Log("refresh_token", r)
	pa, vaild, err := myToken.ParseToken(a)
	if err != nil {
		t.Error(err)
	}
	t.Log("claims:", pa)
	t.Log("vaild:", vaild)
	if pa != uid {
		t.Error()
	}
}

func TestPase(t *testing.T) {
	t.Log(myToken.ParseToken("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1aWQiOjEsInR5cGUiOjAsImV4cCI6MTY0MDMyNzY1NX0.7wqVyWnGAOQ4I2S5u4dhZTnY4k_BRILv-ELKKV_R_H0"))
}
