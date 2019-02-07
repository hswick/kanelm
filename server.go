package main

import (
	"log"
	"fmt"
	"net/http"
	"encoding/json"
)

type Task struct {
	Name string `json:"name"`
	Status string `json:"status"`
}

type Tasks []Task

func tasksHandler(w http.ResponseWriter, r *http.Request) {
	tasks := Tasks{
		Task{Name: "doing stuff", Status: "Todo"},
		Task{Name: "doing things", Status: "Done"},
		Task{Name: "doing thing", Status: "OnGoing"},
	}

	json.NewEncoder(w).Encode(tasks)
}

func deleteTaskHandler(w http.ResponseWriter, r *http.Request) {
	tasks := Tasks{
		Task{Name: "doing stuff", Status: "Todo"},
		Task{Name: "doing things", Status: "Done"},
		Task{Name: "doing thing", Status: "OnGoing"},
	}

	json.NewEncoder(w).Encode(tasks)
	
}

func moveTaskHandler(w http.ResponseWriter, r *http.Request) {
	tasks := Tasks{
		Task{Name: "doing stuff", Status: "Todo"},
		Task{Name: "doing things", Status: "Done"},
		Task{Name: "doing thing", Status: "OnGoing"},
	}

	json.NewEncoder(w).Encode(tasks)
	
}

func routes() {
	http.Handle("/", http.FileServer(http.Dir("./static")))
	http.HandleFunc("/tasks", tasksHandler)
	http.handleFunc("/delete", deleteTaskHandler)
	http.handleFunc("/move", moveTaskHandler)
}

func main() {
	routes()
	fmt.Println("Running Kanelm server at port 8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
