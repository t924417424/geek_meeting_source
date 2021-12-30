package tests

import (
	my_types "GeekMeeting/internal/type"
	"context"
	"testing"
)

func TestContextType(t *testing.T) {
	type e int
	var i e = 0
	ctx := context.WithValue(context.WithValue(context.Background(), i, "1"), my_types.DatabasesKey, "2")
	if ctx.Value(i) == "1" {
		t.Log(ctx.Value(0))
	} else {
		t.Error()
	}
	if ctx.Value(my_types.DatabasesKey) == "2" {
		t.Log(ctx.Value(0))
	} else {
		t.Error()
	}
}
