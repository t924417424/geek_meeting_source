package util

import (
	"crypto/md5"
	"encoding/hex"
)

func Md5(str string) string {
	m := md5.Sum([]byte(str))
	return hex.EncodeToString(m[:])
}

func Md5FromBytes(data []byte) string {
	m := md5.Sum(data)
	return hex.EncodeToString(m[:])
}
