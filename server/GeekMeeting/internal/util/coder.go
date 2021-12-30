package util

import (
	"bytes"
	"encoding/gob"
	"encoding/json"
	"errors"
	"reflect"
)

type encodeType int

const (
	Gob encodeType = iota
	Json
)

var (
	UnknownCode   = errors.New("未知的编码类型")
	DecodeTypeErr = errors.New("解码目标参数需传入指针类型")
)

type coder struct {
	encodeType encodeType
}

func NewCoding(encodeType encodeType) coder {
	return coder{encodeType: encodeType}
}

func (c coder) Encode(data interface{}) ([]byte, error) {
	if c.encodeType == Gob {
		return c.gobEncoder(data)
	} else if c.encodeType == Json {
		return c.jsonEncoder(data)
	}
	return nil, UnknownCode
}

func (c coder) Decode(data []byte, target interface{}) error {
	targetValue := reflect.ValueOf(target)
	if targetValue.Kind() != reflect.Ptr {
		return DecodeTypeErr
	}
	if c.encodeType == Gob {
		return c.gobDecoder(data, target)
	} else if c.encodeType == Json {
		return c.jsonDecoder(data, target)
	}
	return UnknownCode
}

func (c coder) jsonEncoder(data interface{}) ([]byte, error) {
	return json.Marshal(data)
}

func (c coder) gobEncoder(data interface{}) ([]byte, error) {
	var buf bytes.Buffer
	encoder := gob.NewEncoder(&buf)
	err := encoder.Encode(data)
	return buf.Bytes(), err
}

func (c coder) jsonDecoder(data []byte, target interface{}) error {
	return json.Unmarshal(data, target)
}

func (c coder) gobDecoder(data []byte, target interface{}) error {
	return gob.NewDecoder(bytes.NewReader(data)).Decode(target)
}
