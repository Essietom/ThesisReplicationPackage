package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
	"github.com/gorilla/mux"
	_ "github.com/lib/pq"
)

type User struct {
	ID    string    `json:"id"`
	Name  string `json:"name"`
	Email string `json:"email"`
	Address  string `json:"address"`
	School string `json:"school"`
	Color  string `json:"color"`
	Age string `json:"age"`
	Family  string `json:"family"`
	Company string `json:"company"`
}

type LogEntry struct {
	Request   string        `json:"request"`
	StartTime time.Time     `json:"start_time"`
	EndTime   time.Time     `json:"end_time"`
	Duration  time.Duration `json:"duration"`
}

var dynamoDbClient *dynamodb.DynamoDB
var logger *log.Logger

func init() {
    // Create a new session with AWS
    sess, _ := session.NewSession(&aws.Config{
        Region: aws.String("eu-central-1"),
    })

    // Create a DynamoDB client
    dynamoDbClient = dynamodb.New(sess)
	// Create a custom logger with desired configurations
	logger = log.New(log.Writer(), "", log.LstdFlags)

}

func logtime(request string, start time.Time){
	elapsed := time.Since(start)
			logEntry := LogEntry{
			Request:   request,
			StartTime: start,
			EndTime:   time.Now(),
			Duration:  elapsed,
		}

		logJSON, err := json.Marshal(logEntry)
		if err != nil {
			logger.Println("Error marshaling log entry:", err)
		} else {
			logger.Println(string(logJSON))
		}
}


func getUsers(w http.ResponseWriter, r *http.Request) {

	start := time.Now()

	result, err := dynamoDbClient.Scan(&dynamodb.ScanInput{
		TableName: aws.String("container-users"),
	})
	if err != nil {
		log.Println(err)
		http.Error(w, "failed to get users", http.StatusInternalServerError)
		logtime("/get", start)
		return
	}

	var users []User
	err = dynamodbattribute.UnmarshalListOfMaps(result.Items, &users)
	if err != nil {
		log.Println(err)
		http.Error(w, "failed to unmarshal users data", http.StatusInternalServerError)
		logtime("/get", start)
		return
	}

	// Write the users data as JSON to the response
	jsonBytes, err := json.Marshal(users)
	if err != nil {
		http.Error(w, "failed to encode users data", http.StatusInternalServerError)
		logtime("/get", start)
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.Write(jsonBytes)
	logtime("/get", start)
}

// createUser creates a new user in the DynamoDB table
func createUser(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	var user User
	err := json.NewDecoder(r.Body).Decode(&user)
	if err != nil {
		fmt.Println(err)
		http.Error(w, "failed to decode request body", http.StatusBadRequest)
		logtime("/create", start)
		return
	}
	if user.ID == "" {
		user.ID = fmt.Sprintf("%d", time.Now().UnixNano())
	}

	av, err := dynamodbattribute.MarshalMap(user)
	if err != nil {
		fmt.Println(err)
		http.Error(w, "failed to marshal user data", http.StatusInternalServerError)
		logtime("/create", start)
		return
	}

	_, err = dynamoDbClient.PutItem(&dynamodb.PutItemInput{
		TableName: aws.String("container-users"),
		Item:      av,
	})
	if err != nil {
		fmt.Println(err)
		http.Error(w, "failed to create user", http.StatusInternalServerError)
		logtime("/create", start)
		return
	}

	w.WriteHeader(http.StatusCreated)
	logtime("/create", start)
}

// updateUser updates an existing user in the DynamoDB table
func updateUser(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	id := mux.Vars(r)["id"]
	if id == "" {
		http.Error(w, "invalid user id", http.StatusBadRequest)
		logtime("/update", start)
		return
	}

	var user User
	err := json.NewDecoder(r.Body).Decode(&user)
	if err != nil {
		http.Error(w, "failed to decode request body", http.StatusBadRequest)
		logtime("/update", start)
		return
	}

	user.ID = id

	av, err := dynamodbattribute.MarshalMap(user)
	if err != nil {
		http.Error(w, "failed to marshal user data", http.StatusInternalServerError)
		logtime("/update", start)
		return
	}

	_, err = dynamoDbClient.PutItem(&dynamodb.PutItemInput{
		TableName: aws.String("container-users"),
		Item:      av,
	})
	if err != nil {
		http.Error(w, "failed to update user", http.StatusInternalServerError)
		logtime("/update", start)
		return
	}

	w.WriteHeader(http.StatusNoContent)
	logtime("/update", start)
}


func deleteUser(w http.ResponseWriter, r *http.Request) {
	start := time.Now()

	// Get the ID parameter from the URL
	vars := mux.Vars(r)
	id := vars["id"]

	_, err := dynamoDbClient.DeleteItem(&dynamodb.DeleteItemInput{
		TableName: aws.String("container-users"),
		Key: map[string]*dynamodb.AttributeValue{
			"id": {
				S: aws.String(id),
			},
		},
	})
	if err != nil {
		http.Error(w, "failed to delete user", http.StatusInternalServerError)
		logtime("/delete", start)
		return
	}

	w.WriteHeader(http.StatusOK)
	logtime("/delete", start)
}


func healthCheck(w http.ResponseWriter, r *http.Request) {
	w.WriteHeader(http.StatusOK)
}




func main() {
    // Set up the HTTP server and start listening for requests
    router := mux.NewRouter()
	router.HandleFunc("/", healthCheck)
    router.HandleFunc("/users", createUser).Methods(http.MethodPost)
    router.HandleFunc("/users", getUsers).Methods(http.MethodGet)
    router.HandleFunc("/users/{id}", updateUser).Methods(http.MethodPut)
    router.HandleFunc("/users/{id}", deleteUser).Methods(http.MethodDelete)

    log.Println("Starting HTTP server on port 8080")
    log.Fatal(http.ListenAndServe(":8080", router))
}

