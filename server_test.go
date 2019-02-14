package main

import (
	"testing"
	"net/http"
	"encoding/json"
	"net/http/httptest"
	"bytes"
	"log"
	"io/ioutil"
)

func createTable(filename string) {
	query := loadQuery(filename)

	stmt, err := db.Prepare(query)

	if err != nil {
		log.Fatal(err.Error())
	}

	stmt.Exec()	
}

func createTasks() {
	createTable("sql/create_tasks.sql")
}

func createUsers() {
	createTable("sql/create_users.sql")
}

func createProjects() {
	createTable("sql/create_projects.sql")
}

func dropTable(query string) {
	stmt, err := db.Prepare("DROP TABLE IF EXISTS tasks")

	if err != nil {
		log.Fatal(err.Error())
	}

	stmt.Exec()
	
}

func dropTasks() {
	dropTable("DROP TABLE IF EXISTS tasks")
}

func dropUsers() {
	dropTable("DROP TABLE IF EXISTS users")
}

func dropProjects() {
	dropTable("DROP TABLE IF EXISTS projects")
}

func newUser(t *testing.T) (*User) {
	server := httptest.NewServer(http.HandlerFunc(newUserHandler()))
	defer server.Close()

	nu := &NewUser{Name: "userfoo"}
	res, _ := json.Marshal(nu)
	resp, err := http.Post(server.URL, "application/json", bytes.NewBuffer(res))

	if err != nil {
		t.Fatal("Create user failed with:", err.Error())
	}

	if resp.StatusCode != 200 {
		body, _ := ioutil.ReadAll(resp.Body)
		t.Fatal("New user has error", string(body))
	}

	var user User
	err2 := json.NewDecoder(resp.Body).Decode(&user)
	if err2 != nil {
		t.Fatal("Decoding user failed: ", err2.Error())
	}

	if user.Name != "userfoo" {
		t.Fatal("User does not have correct name")
	}

	return &user	
}

func updateUserName(t *testing.T, user *User) {
	server := httptest.NewServer(http.HandlerFunc(updateUserNameHandler()))
	defer server.Close()

	res, _ := json.Marshal(user)
	resp, err := http.Post(server.URL, "application/json", bytes.NewBuffer(res))

	if err != nil {
		t.Fatal("Update user name failed with:", err.Error())
	}

	if resp.StatusCode != 200 {
		body, _ := ioutil.ReadAll(resp.Body)
		t.Fatal("Update user name failed with:", string(body))
	}

}

func getUserById(t *testing.T, id *UserId) (*User) {
	server := httptest.NewServer(http.HandlerFunc(getUserHandler()))
	defer server.Close()

	res, _ := json.Marshal(id)
	resp, err := http.Post(server.URL, "application/json", bytes.NewBuffer(res))

	if err != nil {
		t.Fatal("Getting user by id failed:", err.Error())
	}

	var u User
	err = json.NewDecoder(resp.Body).Decode(&u)
	if err != nil {
		t.Fatal("Decoding user failed: ", err.Error())
	}

	return &u

}

func deleteUser(t *testing.T, user *User) {
	server := httptest.NewServer(http.HandlerFunc(deleteUserHandler()))
	defer server.Close()

	res, _ := json.Marshal(user)
	resp, err := http.Post(server.URL, "application/json", bytes.NewBuffer(res))

	if err != nil {
		t.Fatal("Deleting user failed", err.Error())
	}

	if resp.StatusCode != 200 {
		body, _ := ioutil.ReadAll(resp.Body)
		t.Fatal("Delete user has error", string(body))
	}
		
}

func getUsers(t *testing.T) (Users) {
	server := httptest.NewServer(http.HandlerFunc(getUsersHandler()))
	defer server.Close()

	resp, err := http.Get(server.URL)

	if err != nil {
		t.Fatal("Get users failed with", err.Error())
	}

	if resp.StatusCode != 200 {
		body, _ := ioutil.ReadAll(resp.Body)
		t.Fatal("Get users has error", string(body))
	}	
	
	var users Users
	err2 := json.NewDecoder(resp.Body).Decode(&users)

	if err2 != nil {
		t.Fatal("Decoding users failed", err2.Error())
	}

	return users
}

func newProject(t *testing.T, user *User) (*Project) {
	server := httptest.NewServer(http.HandlerFunc(newProjectHandler()))
	defer server.Close()

	np := &NewProject{Name: "bar", CreatedBy: user.Id}
	res, _ := json.Marshal(np)
	resp, err := http.Post(server.URL, "application/json", bytes.NewBuffer(res))

	if err != nil {
		t.Fatal("Create project failed with:", err.Error())
	}

	if resp.StatusCode != 200 {
		body, _ := ioutil.ReadAll(resp.Body)
		t.Fatal("New project has error", string(body))
	}

	var project Project
	err2 := json.NewDecoder(resp.Body).Decode(&project)
	if err2 != nil {
		t.Fatal("Decoding project failed: ", err2.Error())
	}

	if project.Name != "bar" {
		t.Fatal("Project does not have correct name")
	}

	if project.CreatedBy != user.Id {
		t.Fatal("Project does not have correct created by, is", project.CreatedBy)
	}

	return &project
}

func updateProjectName(t *testing.T, project *Project) {
	server := httptest.NewServer(http.HandlerFunc(updateProjectNameHandler()))
	defer server.Close()

	res, _ := json.Marshal(project)
	resp, err := http.Post(server.URL, "application/json", bytes.NewBuffer(res))

	if err != nil {
		t.Fatal("Update project failed with:", err.Error())
	}

	if resp.StatusCode != 200 {
		body, _ := ioutil.ReadAll(resp.Body)
		t.Fatal("Update project has error", string(body))
	}
}

func getProjects(t *testing.T) (Projects) {
	server := httptest.NewServer(http.HandlerFunc(getProjectsHandler()))
	defer server.Close()

	resp, err := http.Get(server.URL)

	if err != nil {
		t.Fatal("Get projects failed with", err.Error())
	}

	if resp.StatusCode != 200 {
		body, _ := ioutil.ReadAll(resp.Body)
		t.Fatal("Get projects has error", string(body))
	}	
	
	var projects Projects
	err2 := json.NewDecoder(resp.Body).Decode(&projects)

	if err2 != nil {
		t.Fatal("Decoding projects failed", err2.Error())
	}

	return projects	
}

func deleteProject(t *testing.T, project *Project) {
	server := httptest.NewServer(http.HandlerFunc(deleteProjectHandler()))
	defer server.Close()

	res, _ := json.Marshal(project)
	resp, err := http.Post(server.URL, "application/json", bytes.NewBuffer(res))

	if err != nil {
		t.Fatal("Deleting project failed", err.Error())
	}

	if resp.StatusCode != 200 {
		body, _ := ioutil.ReadAll(resp.Body)
		t.Fatal("Delete project has error", string(body))
	}
		
}

func newTask(t *testing.T, user *User, project *Project) (*Task) {
	server := httptest.NewServer(http.HandlerFunc(newTaskHandler()))
	defer server.Close()
	
	nt := &NewTask{Name: "foo", CreatedBy: user.Id, ProjectId: project.Id}
	res, _ := json.Marshal(nt)
	resp, err := http.Post(server.URL, "application/json", bytes.NewBuffer(res))

	if err != nil {
		t.Fatal("Creating task failed with: ", err.Error())
	}

	if resp.StatusCode != 200 {
		body, _ := ioutil.ReadAll(resp.Body)
		t.Fatal("New task has error", string(body))
	}

	var task Task
	err2 := json.NewDecoder(resp.Body).Decode(&task)
	if err2 != nil {
		t.Fatal("Decoding task failed: ", err2.Error())
	}

	if task.Name != "foo" {
		t.Fatal("Task does not have correct name")
	}

	if task.Status != "Todo" {
		t.Fatal("Newly created task has incorrect status. Should be Todo, is", task.Status)
	}

	if task.CreatedBy != user.Id {
		t.Fatal("Task does not have correct created by id", task.CreatedBy)
	}

	if task.ProjectId != project.Id {
		t.Fatal("Task does not have correct project id", task.ProjectId)
	}

	return &task
}

func updateTaskStatus(t *testing.T, task *Task) {
	server := httptest.NewServer(http.HandlerFunc(updateTaskStatusHandler()))
	defer server.Close()
	
	res, _ := json.Marshal(Task{Id: task.Id, Name: task.Name, Status: "OnGoing"})
	resp, err := http.Post(server.URL, "application/json", bytes.NewBuffer(res))

	if err != nil {
		t.Fatal("Moving task failed with: ", err.Error())
	}

	if resp.StatusCode != 200 {
		body, _ := ioutil.ReadAll(resp.Body)
		t.Fatal("Move task has error", string(body))
	}
}

func getProjectTasks(t *testing.T, project *Project) (Tasks) {
	server := httptest.NewServer(http.HandlerFunc(getProjectTasksHandler()))
	defer server.Close()

	res, _ := json.Marshal(project)
	resp, err := http.Post(server.URL, "application/json", bytes.NewBuffer(res))

	if err != nil {
		t.Fatal("Get tasks failed with", err.Error())
	}

	if resp.StatusCode != 200 {
		body, _ := ioutil.ReadAll(resp.Body)
		t.Fatal("Get tasks has error", string(body))
	}	
	
	var tasks Tasks
	err2 := json.NewDecoder(resp.Body).Decode(&tasks)

	if err2 != nil {
		t.Fatal("Decoding tasks failed", err2.Error())
	}

	return tasks
}

func deleteTask(t *testing.T, task *Task) {
	server := httptest.NewServer(http.HandlerFunc(deleteTaskHandler()))
	defer server.Close()
	
	res, _ := json.Marshal(task)
	resp, err := http.Post(server.URL, "application/json", bytes.NewBuffer(res))

	if err != nil {
		t.Fatal("Moving task failed with: ", err.Error())
	}

	if resp.StatusCode != 200 {
		body, _ := ioutil.ReadAll(resp.Body)
		t.Fatal("Move task has error", string(body))
	}
}

func TestIntegrationApi(t *testing.T) {

	// User
	createUsers()

	user := newUser(t)

	updateUserName(t,  &User{Id: user.Id, Name: "ricky"})

	user = getUserById(t, &UserId{Id: user.Id})

	if user.Name != "ricky" {
		t.Fatal("User name should be ricky, but it is", user.Name)
	}

	// Project
	createProjects()

	project := newProject(t, user)

	updateProjectName(t, &Project{Id: project.Id, Name: "galaxy", CreatedBy: project.CreatedBy})

	projects := getProjects(t)

	if projects[0].Name != "galaxy" {
		t.Fatal("Project name should be galaxy, but it is", projects[0].Name)
	
	}

	// Tasks
	createTasks()

	task := newTask(t, user, project)

	updateTaskStatus(t, task)

	tasks := getProjectTasks(t, project)

	if tasks[0].Status != "OnGoing" {
		t.Fatal("Task status should be OnGoing, but it is", tasks[0].Status)
	}

	deleteTask(t, task)

	tasks = getProjectTasks(t, project)

	n := len(tasks)

	if n != 0 {
		t.Fatal("Tasks length should be zero, but it is", n)
	}
	
	dropTasks()

	//Project

	deleteProject(t, project)

	projects = getProjects(t)

	n = len(projects)

	if n != 0 {
		t.Fatal("Projects length should be zero, but it is", n)
	}

	dropProjects()

	//User

	deleteUser(t, user)

	users := getUsers(t)

	n = len(users)

	if n != 0 {
		t.Fatal("Users length should be zero, but it is", n)
	}

	dropUsers()
}
