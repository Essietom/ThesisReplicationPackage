package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"time"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/dynamodb"
	"github.com/aws/aws-sdk-go/service/dynamodb/dynamodbattribute"
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


var dynamoDbClient *dynamodb.DynamoDB

func init() {
    // Create a new session with AWS
    sess, _ := session.NewSession(&aws.Config{
        Region: aws.String("eu-central-1"),
    })

    // Create a DynamoDB client
    dynamoDbClient = dynamodb.New(sess)
}

func main() {
    lambda.Start(HandleRequest)
}


func getUsers(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	// svc, err := getDBClient()
	// if err != nil {
	// 	return events.APIGatewayProxyResponse{}, errors.New("failed to connect to DB")
	// }
	result, err := dynamoDbClient.Scan(&dynamodb.ScanInput{
		TableName: aws.String("lambda-users"),
	})
	if err != nil {
		log.Printf("Error scanning DynamoDB table: %v", err)
		return events.APIGatewayProxyResponse{}, errors.New("failed to retrieve users")
	}

	var users []User
	err = dynamodbattribute.UnmarshalListOfMaps(result.Items, &users)
	if err != nil {
		return events.APIGatewayProxyResponse{}, errors.New("failed to unmarshal users")
	}

	body, _ := json.Marshal(users)

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Body:       string(body),
	}, nil
}

func createUser(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	var user User
	err := json.Unmarshal([]byte(request.Body), &user)
	if err != nil {
		return events.APIGatewayProxyResponse{}, errors.New("invalid request body")
	}

	if user.ID == "" {
		user.ID = fmt.Sprintf("%d", time.Now().UnixNano())
	}


	av, err := dynamodbattribute.MarshalMap(user)
	if err != nil {
		return events.APIGatewayProxyResponse{}, errors.New("failed to marshal item")
	}

	// svc, err := getDBClient()
	// if err != nil {
	// 	return events.APIGatewayProxyResponse{}, errors.New("failed to connect to DB")
	// }
	_, err = dynamoDbClient.PutItem(&dynamodb.PutItemInput{
		TableName: aws.String("lambda-users"),
		Item:      av,
	})
	if err != nil {
		log.Printf("Error creating user: %v", err)
		return events.APIGatewayProxyResponse{}, errors.New("failed to create item")
	}

	body, _ := json.Marshal(user)

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusCreated,
		Body:       string(body),
	}, nil
}

func updateUser(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	id := request.PathParameters["id"]
	if id == "" {
		return events.APIGatewayProxyResponse{}, errors.New("invalid user id")
	}

	var user User
	err := json.Unmarshal([]byte(request.Body), &user)
	if err != nil {
		return events.APIGatewayProxyResponse{}, errors.New("invalid request body")
	}

	user.ID = id

	av, err := dynamodbattribute.MarshalMap(user)
	if err != nil {
		return events.APIGatewayProxyResponse{}, errors.New("failed to marshal user")
	}


	_, err = dynamoDbClient.PutItem(&dynamodb.PutItemInput{
		TableName: aws.String("lambda-users"),
		Item:      av,
	})
	if err != nil {
		log.Printf("Error update user: %v", err)
		return events.APIGatewayProxyResponse{}, errors.New("failed to update user")
	}

	body, _ := json.Marshal(user)

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Body:       string(body),
	}, nil
}


func deleteUser(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	id := request.PathParameters["id"]
	if id == "" {
		return events.APIGatewayProxyResponse{}, errors.New("invalid user id")
	}

	// svc, err := getDBClient()
	// if err != nil {
	// 	return events.APIGatewayProxyResponse{}, errors.New("failed to connect to DB")
	// }

	_, err := dynamoDbClient.DeleteItem(&dynamodb.DeleteItemInput{
		TableName: aws.String("lambda-users"),
		Key: map[string]*dynamodb.AttributeValue{
			"id": {
				S: aws.String(id),
			},
		},
	})
	if err != nil {
		log.Printf("Error deleting user: %v", err)
		return events.APIGatewayProxyResponse{}, errors.New("failed to delete user")
	}

	return events.APIGatewayProxyResponse{
		StatusCode: http.StatusOK,
		Body:       "User deleted successfully",
	}, nil
}









func HandleRequest(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
    switch request.HTTPMethod {
		case "GET":
			return getUsers(ctx, request)
		case "POST":
			return createUser(ctx, request)
		case "PUT":
			return updateUser(ctx, request)
		case "DELETE":
			return deleteUser(ctx, request)
		default:
			return events.APIGatewayProxyResponse{StatusCode: 400, Body: "method not allowed"}, nil
		}

}

