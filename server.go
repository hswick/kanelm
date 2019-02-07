package main

import (
	"log"
	"fmt"
	"net/http"
	"encoding/json"
	"math/rand"
)

type Task struct {
	Id int `json:"id"`
	Name string `json:"name"`
	Status string `json:"status"`
}

type NewTask struct {
	Name string `json:"name"`
}

type Tasks []Task

func tasksHandler(w http.ResponseWriter, r *http.Request) {
	tasks := Tasks{
		Task{Id: 1, Name: "doing stuff", Status: "Todo"},
		Task{Id: 2, Name: "doing things", Status: "Done"},
		Task{Id: 3, Name: "doing thing", Status: "OnGoing"},
	}

	json.NewEncoder(w).Encode(tasks)
	
}

func newTaskHandler(w http.ResponseWriter, r *http.Request) {
	var nt NewTask

	if r.Body == nil {
		http.Error(w, "Please send a request body", 400)
		return
	}

	err := json.NewDecoder(r.Body).Decode(&nt)
	if err != nil {
		http.Error(w, err.Error(), 400)
		return
	}

	json.NewEncoder(w).Encode(
		Task{Id: rand.Int(), Name: nt.Name, Status: "Todo"}, 
	)
}

func deleteTaskHandler(w http.ResponseWriter, r *http.Request) {
	var t Task

	if r.Body == nil {
		http.Error(w, "Please send a request body", 400)
		return
	}

	err := json.NewDecoder(r.Body).Decode(&t)
	if err != nil {
		http.Error(w, err.Error(), 400)
		return
	}
}

func moveTaskHandler(w http.ResponseWriter, r *http.Request) {
	var t Task

	if r.Body == nil {
		http.Error(w, "Please send a request body", 400)
		return
	}

	err := json.NewDecoder(r.Body).Decode(&t)
	if err != nil {
		http.Error(w, err.Error(), 400)
		return
	}

	
}

// TODO: Add task decoder middleware

func routes() {
	http.Handle("/", http.FileServer(http.Dir("./static")))
	http.HandleFunc("/tasks", tasksHandler)
	http.HandleFunc("/new", newTaskHandler)
	http.HandleFunc("/delete", deleteTaskHandler)
	http.HandleFunc("/move", moveTaskHandler)
}

func main() {
	routes()
	fmt.Println("Running Kanelm server at port 8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
