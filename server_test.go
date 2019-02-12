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

func createTable() {
	query := loadQuery("sql/create_tasks.sql")

	stmt, err := db.Prepare(query)

	if err != nil {
		log.Fatal(err.Error())
	}

	stmt.Exec()
}

func dropTable() {
	stmt, err := db.Prepare("DROP TABLE IF EXISTS tasks")

	if err != nil {
		log.Fatal(err.Error())
	}

	stmt.Exec()
}

func newTask(t *testing.T) (*Task) {
	server := httptest.NewServer(http.HandlerFunc(newTaskHandler()))
	defer server.Close()
	
	nt := &NewTask{Name: "foo"}
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

	return &task
}

func moveTask(t *testing.T, task *Task) {
	server := httptest.NewServer(http.HandlerFunc(moveTaskHandler()))
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

func getTasks(t *testing.T) (Tasks) {
	server := httptest.NewServer(http.HandlerFunc(getTasksHandler()))
	defer server.Close()

	resp, err := http.Get(server.URL)

	if err != nil {
		t.Fatal("Get tasks failed with", err.Error())
	}

	if resp.StatusCode != 200 {
		body, _ := ioutil.ReadAll(resp.Body)
		t.Fatal("Move task has error", string(body))
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

	createTable()

	task := newTask(t)

	moveTask(t, task)

	tasks := getTasks(t)

	if tasks[0].Status != "OnGoing" {
		t.Fatal("Task status should be OnGoing, but it is", tasks[0].Status)
	}

	deleteTask(t, task)

	tasks = getTasks(t)

	n := len(tasks)

	if n != 0 {
		t.Fatal("Tasks length should be zero, but it is", n)
	}
	
	dropTable()
}
