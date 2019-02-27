package main

import (
	"github.com/BurntSushi/toml"
	"log"
	"io/ioutil"
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
		if s2[k] != nil {
			newSet.Add(k)
		}
	}
	return newSet
}

func (s []string) Set() (set) {
	st := make(set)
	for _, s := range strings {
		st.Add(s)
	}
	return st
}

type Permissions map[string]map[string]struct{}

type TempPermissions map[string]map[string][]string

func (t TempPermissions) Permissions() (Permissions) {
	var p Permissions
	for k := range t {
		for k2 := range t[k] {
			p[k][k2] = t[k][k2].Set()
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
		log.Fatal("Failed to decode: %s", err.Error())
	}

	return temp.Permissions()
}

var permissions Permissions = loadPermissions("permissions.toml")

type RoleRequest struct {
	Entity string
	Action string
	ActiveUserId int64
	User *User	
	Project *Project
	Task *Task
}

func prepareQuery(path string) string {
	query := loadQuery(path)
	stmt, err := db.Prepare(query)
	if err != nil {
		log.Fatal("Was unable to prepare query: %s", path)
	}
	return stmt
}

var checkAdminQuery string = prepareQuery("sql/check_admin.sql")

var checkProjectOwner string = prepareQuery("sql/check_project_owner.sql")

var checkTaskOwner string = prepareQuery("sql/check_task_assignee.sql")

func (r *RoleRequest) Satisfied() (bool) {
	if r.Entity == nil {
		log.Fatal("RoleRequest is missing Entity field (type string)")
	}

	if r.Action == nil {
		log.Fatal("RoleRequest is missing Action field (type string)")
	}

	if r.ActiveUserId == nil {
		log.Fatal("RoleRequest is missing ActiveUserId field (type int64)")
	}	
	
	if r.UserId == nil {
		log.Fatal("RoleRequest is missing User field (type *User)")
	}

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
	err = checkAdminQuery.QueryRow(r.ActiveUserId).Scan(&admin)

	if err != nil {
		log.Fatal("Admin query failed")
	}

	if r.UserId == r.ActiveUserId {
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
