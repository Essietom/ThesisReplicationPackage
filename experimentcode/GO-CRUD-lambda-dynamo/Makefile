.PHONY: build clean deploy

build:
	go get ./...
	go mod vendor
	env GOOS=linux GOARCH=amd64 go build -o bin/main main.go 

clean:
	rm -rf ./bin ./vendor

deploy: clean build
	sls deploy --verbose
