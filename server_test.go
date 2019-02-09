package server

import (
	"testing"
	"net/http"
	"encoding/json"
	"bytes"
	"io/ioutil"
)

func baseUrl() (string) {
	return "http://localhost:8080"
}

func TestNewTask(t *testing.T) {
	nt := &NewTask{Name: "foo"}

	byteData, _ := json.Marshal(nt)

	result, err := http.Post(baseUrl() + "/new", "application/json", bytes.NewBuffer(byteData))

	if err != nil {
		t.Error("New Task request failed", err.Error())
		return
	}

	defer result.Body.Close()

	bodyBytes, err := ioutil.ReadAll(result.Body)
	bodyString := string(bodyBytes)	

	if result.StatusCode != 200 {
		t.Error(bodyString, result.StatusCode)
		return
	}

	var task Task

	err2 := json.NewDecoder(result.Body).Decode(&task)

	if err2 != nil {
		t.Error("New task decoding failed with", err2.Error()) 
	}
}
