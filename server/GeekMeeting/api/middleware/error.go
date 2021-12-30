package middleware

import (
	"log"
	"net/http"
)

func PaincHandle(rw http.ResponseWriter, r *http.Request, i interface{}) {
	log.Println(i)
	rw.WriteHeader(http.StatusInternalServerError)
	_, _ = rw.Write(nil)
}
