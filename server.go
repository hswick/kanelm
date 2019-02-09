package main

import (
	"log"
	"fmt"
	"os"
	"net/http"
	"encoding/json"
	"io/ioutil"
	"database/sql"
	_ "github.com/lib/pq"
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

func loadQuery(filename string) (string) {
	content, err := ioutil.ReadFile(filename)
	if err != nil {
		log.Fatal(err)
	}
	return string(content[:])
}

func getTasksHandler(db *sql.DB) func(http.ResponseWriter, *http.Request) {

	query := loadQuery("sql/get_tasks.sql")

	return func(w http.ResponseWriter, r *http.Request) {
		rows, err := db.Query(query)
		
		if err != nil {
			http.Error(w, err.Error(), 400)
			return
		}
		
		json.NewEncoder(w).Encode(rows)
	}
}

func newTaskHandler(db *sql.DB) func(http.ResponseWriter, *http.Request) {

	query := loadQuery("sql/new_task.sql")

	return func(w http.ResponseWriter, r *http.Request) {

		var nt NewTask

		if r.Body == nil {
			http.Error(w, "Please send a request body", 400)
			return
		}

		jsonerr := json.NewDecoder(r.Body).Decode(&nt)
		if jsonerr != nil {
			http.Error(w, jsonerr.Error(), 400)
			return
		}
				
		rows, dberr := db.Query(fmt.Sprintf(query, nt.Name, "Todo"))
		if dberr != nil {
			http.Error(w, dberr.Error(), 500)
			return
		}
		
		json.NewEncoder(w).Encode(rows)
	}
}

func deleteTaskHandler(db *sql.DB) func(http.ResponseWriter, *http.Request) {

	query := loadQuery("sql/delete_task.sql")

	return func (w http.ResponseWriter, r *http.Request) {
		var t Task

		if r.Body == nil {
			http.Error(w, "Please send a request body", 400)
			return
		}

		jsonerr := json.NewDecoder(r.Body).Decode(&t)
		if jsonerr != nil {
			http.Error(w, jsonerr.Error(), 400)
			return
		}

		rows, dberr := db.Query(fmt.Sprintf(query, t.Id))
		if dberr != nil {
			http.Error(w, dberr.Error(), 500)
			return
		}

		json.NewEncoder(w).Encode(rows)
		
	}

}

func moveTaskHandler(db *sql.DB) func(http.ResponseWriter, *http.Request) {

	query := loadQuery("sql/move_task.sql")
	
	return func (w http.ResponseWriter, r *http.Request) {
		var t Task

		if r.Body == nil {
			http.Error(w, "Please send a request body", 400)
			return
		}

		jsonerr := json.NewDecoder(r.Body).Decode(&t)
		if jsonerr != nil {
			http.Error(w, jsonerr.Error(), 400)
			return
		}

		rows, dberr := db.Query(fmt.Sprintf(query, t.Status, t.Id))
		if dberr != nil {
			http.Error(w, dberr.Error(), 500)
			return
		}

		json.NewEncoder(w).Encode(rows)
	}
}

type Conn struct {
	User string `json:"user"`
	ConnectionStr string `json:"connection-str"`
}

func dbConnection() (* sql.DB) {
	rdr, err := os.Open("db.json")
	if err != nil {
		log.Fatal(err)
	}

	var c Conn

	jsonerr := json.NewDecoder(rdr).Decode(&c)

	if jsonerr != nil {
		log.Fatal(jsonerr)
	}

	db, dberr := sql.Open(c.User, c.ConnectionStr)

	if dberr != nil {
		log.Fatal(dberr)
	}
	
	return db
}

func routes() {

	db := dbConnection()
	
	http.Handle("/", http.FileServer(http.Dir("./static")))
	http.HandleFunc("/tasks", getTasksHandler(db))
	http.HandleFunc("/new", newTaskHandler(db))
	http.HandleFunc("/delete", deleteTaskHandler(db))
	http.HandleFunc("/move", moveTaskHandler(db))
}

func main() {
	routes()
	fmt.Println("Running Kanelm server at port 8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
