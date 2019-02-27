import (
	"github.com/robfig/cron"
)

type AuthCache map[string]*ActiveUser

var auth AuthCache

func (a AuthCache) Insert(token string, user *ActiveUser) {
	a[token] = user
}

func (a AuthCache) Get(token string) (*ActiveUser) {
	u := a[token]

	if u == nil {
		log.Fatal("Could not find UserId")
	}

	return u
}

func (a AuthCache) UserId(token string) (int64) {
	return a.Get(token).Id
}

func (a AuthCache) Delete(token string) {
	delete(a, token)
}

func (a AuthCache) GarbageCollector() {
	c := cron.New()
	c.AddFunc("@every 1h30m", func() {
		for token, user := range a {
			if user.CreatedAt < 41 {
				a.Delete(token)
			}
		}
	})
	c.Start()
}
