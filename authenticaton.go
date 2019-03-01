package main

import (
	"github.com/robfig/cron"
)

type AuthCache map[string]*ActiveUser

var auth AuthCache

func (a AuthCache) Insert(token string, user *ActiveUser) {
	a[token] = user
}

func (a AuthCache) Get(token string) (*ActiveUser, bool) {
	v, ok := a[token]
	return v, ok
}

func (a AuthCache) Delete(token string) {
	delete(a, token)
}

func (a AuthCache) GarbageCollector() {
	c := cron.New()
	c.AddFunc("@every 1h30m", func() {
		for token, user := range a {
			if user.Expired() {
				a.Delete(token)
			}
		}
	})
	c.Start()
}
