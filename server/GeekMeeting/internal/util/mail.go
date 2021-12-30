package util

import (
	"GeekMeeting/internal/config"
	itypes "GeekMeeting/internal/type"
	"context"
	"log"
	"regexp"
	"sync"

	"gopkg.in/gomail.v2"
)

const reEmail = `[\w\.]+@\w+\.[a-z]{2,3}(\.[a-z]{2,3})?`

var (
	regx     = regexp.MustCompile(reEmail)
	mail     *gomail.Dialer
	mailOnce sync.Once
	conf     config.TomlMap
)

func SendEmailTo(ctx context.Context, subject, to, content string) error {
	mailOnce.Do(func() {
		conf = ctx.Value(itypes.ConfigKey).(config.TomlMap)
		// log.Println(conf.Mail.Server, conf.Mail.Port, conf.Mail.Username, conf.Mail.Password)
		mail = gomail.NewDialer(conf.Mail.Server, conf.Mail.Port, conf.Mail.Username, conf.Mail.Password)
	})
	sender, err := mail.Dial()
	if err != nil {
		log.Printf("Could not send email to %q: %v", to, err)
		return err
	}
	m := gomail.NewMessage()
	m.SetHeader("From", conf.Mail.Name)
	m.SetAddressHeader("To", to, to)
	m.SetHeader("Subject", subject)
	m.SetBody("text/html", content)

	if err := gomail.Send(sender, m); err != nil {
		log.Printf("Could not send email to %q: %v", to, err)
		return err
	}
	return nil
}

func VerifyMail(mail string) bool {
	return regx.MatchString(mail)
}
