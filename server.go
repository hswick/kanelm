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
	Id int64 `json:"id"`
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

type Conn struct {
	Driver string `json:"driver"`
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

	db, dberr := sql.Open(c.Driver, c.ConnectionStr)

	if dberr != nil {
		log.Fatal(dberr)
	}
	
	return db
}

var db *sql.DB = dbConnection()

func getTasksHandler() func(http.ResponseWriter, *http.Request) {

	query := loadQuery("sql/get_tasks.sql")

	return func(w http.ResponseWriter, r *http.Request) {

		tasks := make(Tasks, 0)

		rows, err := db.Query(query)

		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		
		defer rows.Close()

		for rows.Next() {
			task := Task{}
			
			err := rows.Scan(&task.Id, &task.Name, &task.Status)

			if err != nil {
				http.Error(w, err.Error(), 500)
				return
			}

			tasks = append(tasks, task)
		}

		err2 := rows.Err()

		if err2 != nil {
			http.Error(w, err2.Error(), 500)
			return
		}
				
		json.NewEncoder(w).Encode(&tasks)
	}
}

func newTaskHandler() func(http.ResponseWriter, *http.Request) {

	query := loadQuery("sql/new_task.sql")
	stmt, err := db.Prepare(query)

	if err != nil {
		log.Fatal(err.Error())
	}

	return func(w http.ResponseWriter, r *http.Request) {

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

		var id int64
		err2 := stmt.QueryRow(nt.Name, "Todo").Scan(&id)

		if err2 != nil {
			http.Error(w, err2.Error(), 500)
			return
		}
				
		json.NewEncoder(w).Encode(&Task{Id: id, Name: nt.Name, Status: "Todo"})
	}
}

func deleteTaskHandler() func(http.ResponseWriter, *http.Request) {

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

		_, dberr := db.Query(query, t.Id)
		if dberr != nil {
			http.Error(w, dberr.Error(), 500)
			return
		}
	}
}

func moveTaskHandler() func(http.ResponseWriter, *http.Request) {

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

		_, dberr := db.Query(query, t.Status, t.Id)
		if dberr != nil {
			http.Error(w, dberr.Error(), 500)
			return
		}
	}
}

func routes() {	
	http.Handle("/", http.FileServer(http.Dir("./static")))
	http.HandleFunc("/tasks", getTasksHandler())
	http.HandleFunc("/new", newTaskHandler())
	http.HandleFunc("/delete", deleteTaskHandler())
	http.HandleFunc("/move", moveTaskHandler())
}

func main() {
	routes()
	fmt.Println("Running Kanelm server at port 8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
