package main

import (
	"github.com/BurntSushi/toml"
	"log"
	"io/ioutil"
	"database/sql"
)

type set map[string]struct{}

func (s set) Has(str string) (bool) {
	_, ok := s[str]
	return ok
}

func (s set) Add(str string) {
	var temp struct{}
	s[str] = temp
}

func (s set) Intersect(s2 set) (set) {
	var newSet set
	for k := range s {
		_, ok := s2[k]
		if ok {
			newSet.Add(k)
		}
	}
	return newSet
}

func toSet(s []string) (set) {
	st := make(set)
	for _, v := range s {
		st.Add(v)
	}
	return st
}

type Permissions map[string]map[string]set

type TempPermissions map[string]map[string][]string

func (t TempPermissions) Permissions() (Permissions) {
	p := make(Permissions)
	for k := range t {
		p[k] = make(map[string]set)
		for k2 := range t[k] {
			p[k][k2] = toSet(t[k][k2])
		}
	}
	return p
}

func loadPermissions(filename string) (Permissions) {
	tomlData, err := ioutil.ReadFile(filename)
	if err != nil {
		log.Fatal(err)
	}

	var temp TempPermissions
	if _, err := toml.Decode(string(tomlData), &temp); err != nil {
		log.Fatal(err.Error())
	}

	return temp.Permissions()
}

var permissions Permissions = loadPermissions("permissions.toml")

type RoleRequest struct {
	Entity string
	Action string
	ActiveUserId int64
	UserId *int64	
	ProjectId *int64
	TaskId *int64
}

func prepareQuery(path string) (*sql.Stmt) {
	query := loadQuery(path)
	stmt, err := db.Prepare(query)
	if err != nil {
		log.Fatal("Was unable to prepare query: " + path + " " + err.Error())
	}
	return stmt
}

var checkAdminQuery *sql.Stmt = prepareQuery("sql/check_admin.sql")	

var checkProjectOwnerQuery *sql.Stmt = prepareQuery("sql/check_project_owner.sql")

var checkTaskOwnerQuery *sql.Stmt = prepareQuery("sql/check_task_assignee.sql")

func (r *RoleRequest) Satisfied() (bool) {

	entity := permissions[r.Entity]
	if entity == nil {
		log.Fatal("RoleRequest Entity is unavailable")
	}

	action := entity[r.Action]
	if action == nil {
		log.Fatal("RoleRequest Action is unavailable")
	}

	var roles set

	var admin bool
	err := checkAdminQuery.QueryRow(r.ActiveUserId).Scan(&admin)

	if err != nil {
		log.Fatal("Admin query failed")
	}

	if r.UserId == nil {
		log.Fatal("User id query failed")
	}

	if *r.UserId == r.ActiveUserId {
		roles.Add("user owner")
	}

	if r.ProjectId != nil {
		var projectOwner bool
		err = checkProjectOwnerQuery.QueryRow(r.ProjectId, r.ActiveUserId).Scan(&projectOwner)

		if err != nil {
			log.Fatal("check project owner query failed")
		}

		if projectOwner {
			roles.Add("project owner")
		}
	}

	if r.TaskId != nil {
		var taskOwner bool
		err = checkTaskOwnerQuery.QueryRow(r.TaskId, r.ActiveUserId).Scan(&taskOwner)

		if err != nil {
			log.Fatal("check task owner query failed")
		}
		roles.Add("task owner")
	}

	permittedRoles := roles.Intersect(action)

	n := len(permittedRoles)

	if n > 0 {
		return true
	}

	return false
}
