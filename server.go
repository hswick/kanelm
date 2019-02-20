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

type User struct {
	Id int64 `json:"id"`
	Name string `json:"name"`
}

type NewUser struct {
	Name string `json:"name"`
}

type UserId struct {
	Id int64 `json:"id"`
}

type Users []User

type Project struct {
	Id int64 `json:"id"`
	Name string `json:"name"`
	CreatedBy int64 `json:"created-by"` 
}

type NewProject struct {
	Name string `json:"name"`
	CreatedBy int64 `json:"created-by"`
}

type Projects []Project

type Task struct {
	Id int64 `json:"id"`
	Name string `json:"name"`
	Status string `json:"status"`
	ProjectId int64 `json:"project-id"`
	CreatedBy int64 `json:"created-by"`
}

type NewTask struct {
	Name string `json:"name"`
	CreatedBy int64 `json:"created-by"`
	ProjectId int64 `json:"project-id"`
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

func newUserHandler() func(http.ResponseWriter, *http.Request) {

	query := loadQuery("sql/new_user.sql")
	stmt, err := db.Prepare(query)

	if err != nil {
		log.Fatal(err.Error())
	}

	return func(w http.ResponseWriter, r *http.Request) {

		var nu NewUser

		if r.Body == nil {
			http.Error(w, "Please send a request body", 400)
			return
		}

		err := json.NewDecoder(r.Body).Decode(&nu)
		if err != nil {
			http.Error(w, err.Error(), 400)
			return
		}

		var id int64
		err2 := stmt.QueryRow(nu.Name).Scan(&id)

		if err2 != nil {
			http.Error(w, err2.Error(), 500)
			return
		}
				
		json.NewEncoder(w).Encode(&User{Id: id, Name: nu.Name})
	}
}

func updateUserNameHandler() func(http.ResponseWriter, *http.Request) {
	query := loadQuery("sql/update_user_name.sql")
	stmt, err := db.Prepare(query)

	if err != nil {
		log.Fatal(err.Error())
	}

	return func(w http.ResponseWriter, r *http.Request) {

		var u User

		if r.Body == nil {
			http.Error(w, "Please send a request body", 400)
			return
		}

		err := json.NewDecoder(r.Body).Decode(&u)
		if err != nil {
			http.Error(w, err.Error(), 400)
			return
		}

		_, dberr := stmt.Exec(u.Id, u.Name)
		if dberr != nil {
			http.Error(w, dberr.Error(), 500)
			return
		}	
	}	
}

func getUserHandler() func(http.ResponseWriter, *http.Request) {

	query := loadQuery("sql/get_user.sql")
	stmt, err := db.Prepare(query)
	if err != nil {
		log.Fatal(err.Error())
	}

	return func(w http.ResponseWriter, r *http.Request) {

		var id UserId

		if r.Body == nil {
			http.Error(w, "Please send a request body", 400)
			return
		}
		
		err := json.NewDecoder(r.Body).Decode(&id)
		if err != nil {
			http.Error(w, err.Error(), 400)
			return
		}

		var u User
		err = stmt.QueryRow(id.Id).Scan(&u.Id, &u.Name)

		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
						
		json.NewEncoder(w).Encode(&u)
	}
	
}

func getUsersHandler() func(http.ResponseWriter, *http.Request) {

	query := loadQuery("sql/get_users.sql")

	return func(w http.ResponseWriter, r *http.Request) {

		users := make(Users, 0)

		rows, err := db.Query(query)

		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		
		defer rows.Close()

		for rows.Next() {
			user := User{}
			
			err := rows.Scan(&user.Id, &user.Name)

			if err != nil {
				http.Error(w, err.Error(), 500)
				return
			}

			users = append(users, user)
		}

		err2 := rows.Err()

		if err2 != nil {
			http.Error(w, err2.Error(), 500)
			return
		}
				
		json.NewEncoder(w).Encode(&users)
	}	
}

func deleteUserHandler() func(http.ResponseWriter, *http.Request) {
	query := loadQuery("sql/delete_user.sql")
	stmt, err := db.Prepare(query)

	if err != nil {
		log.Fatal(err.Error())
	}
	
	return func (w http.ResponseWriter, r *http.Request) {

		if r.Body == nil {
			http.Error(w, "Please send a request body", 400)
			return
		}

		var u User				
		err := json.NewDecoder(r.Body).Decode(&u)

		_, err = stmt.Exec(u.Id)
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
	}	
}

func newProjectHandler() func(http.ResponseWriter, *http.Request) {

	query := loadQuery("sql/new_project.sql")
	stmt, err := db.Prepare(query)

	if err != nil {
		log.Fatal(err.Error())
	}

	return func(w http.ResponseWriter, r *http.Request) {

		var np NewProject

		if r.Body == nil {
			http.Error(w, "Please send a request body", 400)
			return
		}

		err := json.NewDecoder(r.Body).Decode(&np)
		if err != nil {
			http.Error(w, err.Error(), 400)
			return
		}

		var id int64
		err2 := stmt.QueryRow(np.Name, np.CreatedBy).Scan(&id)

		if err2 != nil {
			http.Error(w, err2.Error(), 500)
			return
		}
				
		json.NewEncoder(w).Encode(&Project{Id: id, Name: np.Name, CreatedBy: np.CreatedBy})
	}	
}

func updateProjectNameHandler() func(http.ResponseWriter, *http.Request) {

	query := loadQuery("sql/update_project_name.sql")
	stmt, err := db.Prepare(query)

	if err != nil {
		log.Fatal(err.Error())
	}

	return func(w http.ResponseWriter, r *http.Request) {

		var p Project

		if r.Body == nil {
			http.Error(w, "Please send a request body", 400)
			return
		}

		err := json.NewDecoder(r.Body).Decode(&p)
		if err != nil {
			http.Error(w, err.Error(), 400)
			return
		}

		_, dberr := stmt.Exec(p.Id, p.Name)
		if dberr != nil {
			http.Error(w, dberr.Error(), 500)
			return
		}
	}	
}

func getProjectsHandler() func(http.ResponseWriter, *http.Request) {

	query := loadQuery("sql/get_projects.sql")

	return func(w http.ResponseWriter, r *http.Request) {

		projects := make(Projects, 0)

		rows, err := db.Query(query)

		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		
		defer rows.Close()

		for rows.Next() {
			project := Project{}
			
			err := rows.Scan(&project.Id, &project.Name, &project.CreatedBy)

			if err != nil {
				http.Error(w, err.Error(), 500)
				return
			}

			projects = append(projects, project)
		}

		err = rows.Err()

		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
				
		json.NewEncoder(w).Encode(&projects)
	}	
}

func deleteProjectHandler() func(http.ResponseWriter, *http.Request) {

	query := loadQuery("sql/delete_project.sql")
	stmt, err := db.Prepare(query)

	if err != nil {
		log.Fatal(err.Error())
	}
	
	return func (w http.ResponseWriter, r *http.Request) {

		if r.Body == nil {
			http.Error(w, "Please send a request body", 400)
			return
		}

		var p Project				
		err := json.NewDecoder(r.Body).Decode(&p)

		_, err = stmt.Exec(p.Id)
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
	}	
}

func getProjectTasksHandler() func(http.ResponseWriter, *http.Request) {

	query := loadQuery("sql/get_project_tasks.sql")

	return func(w http.ResponseWriter, r *http.Request) {

		if r.Body == nil {
			http.Error(w, "Please send a body with your request", 400)
			return
		}

		var p Project		
		err := json.NewDecoder(r.Body).Decode(&p)

		if err != nil {
			http.Error(w, err.Error(), 400)
			return
		}

		rows, err := db.Query(query, p.Id)

		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		
		defer rows.Close()

		tasks := make(Tasks, 0)		

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
		err2 := stmt.QueryRow(nt.Name, "Todo", nt.ProjectId, nt.CreatedBy).Scan(&id)

		if err2 != nil {
			http.Error(w, err2.Error(), 500)
			return
		}
				
		json.NewEncoder(w).Encode(&Task{Id: id, Name: nt.Name, Status: "Todo", CreatedBy: nt.CreatedBy, ProjectId: nt.ProjectId})
	}
}

func deleteTaskHandler() func(http.ResponseWriter, *http.Request) {

	query := loadQuery("sql/delete_task.sql")
	stmt, err := db.Prepare(query)

	if err != nil {
		log.Fatal(err.Error())
	}

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

		_, dberr := stmt.Exec(t.Id)
		if dberr != nil {
			http.Error(w, dberr.Error(), 500)
			return
		}
	}
}

func updateTaskStatusHandler() func(http.ResponseWriter, *http.Request) {

	query := loadQuery("sql/update_task_status.sql")
	stmt, err := db.Prepare(query)
	if err != nil {
		log.Fatal(err.Error())
	}
	
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

		_, dberr := stmt.Exec(t.Id, t.Status)
		if dberr != nil {
			http.Error(w, dberr.Error(), 500)
			return
		}
	}
}

func routes() {	
	http.Handle("/", http.FileServer(http.Dir("./static")))
}

func main() {
	routes()
	fmt.Println("Running Kanelm server at port 8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
