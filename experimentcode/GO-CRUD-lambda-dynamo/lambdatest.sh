#!/bin/bash

# Create the result folder
RESULT_FOLDER="lambda15-100users"
mkdir "$RESULT_FOLDER"


# Set AWS region and profile
export AWS_DEFAULT_REGION=eu-central-1

# Build the application
make build

# Deploy the serverless application
serverless deploy

API_ENDPOINT="$(serverless info --verbose | grep ServiceEndpoint | sed s/ServiceEndpoint\:\ //g)"

# Set the start times for the resource usage data to be exported
START_TIME=$(date -u +%s)

echo "API endpoint URL: $API_ENDPOINT"


# Run Locust load test
LOCUSTFILE="locustfile.py"
USERS=100
HATCH_RATE=1
DURATION=3600
LOCUSTRESULT_FILE=lambdalocustresult



locust -f $LOCUSTFILE  --headless -u $USERS -r $HATCH_RATE -t $DURATION --host="$API_ENDPOINT" --csv="$RESULT_FOLDER/${LOCUSTRESULT_FILE}"
# locust -f $LOCUSTFILE  -u $USERS -r $HATCH_RATE -t $DURATION --host="$API_ENDPOINT" --csv="$RESULT_FOLDER/${LOCUSTRESULT_FILE}"

#export resource usage (execution time) for the lambda functions

# Set the end times for the resource usage data to be exported
END_TIME=$(date -u +%s)

# Set the name of your serverless application
SERVERLESS_APP_NAME="go-crud-serverless-staging"
FUNCTION_NAMES=("${SERVERLESS_APP_NAME}-createUser" "${SERVERLESS_APP_NAME}-getUsers" "${SERVERLESS_APP_NAME}-deleteUser" "${SERVERLESS_APP_NAME}-updateUser")
LOG_GROUP_NAMES=("/aws/lambda/${SERVERLESS_APP_NAME}-createUser" "/aws/lambda/${SERVERLESS_APP_NAME}-getUsers" "/aws/lambda/${SERVERLESS_APP_NAME}-deleteUser" "/aws/lambda/${SERVERLESS_APP_NAME}-updateUser")


for function_name in "${FUNCTION_NAMES[@]}"; do
    query_results_file="${function_name}_query_results.json"
    query_id=$(aws logs start-query \
        --log-group-name "/aws/lambda/$function_name" \
        --query-string 'fields @timestamp, @message, @logStream, @log
                        | sort @timestamp desc
                        | limit 20
                        | filter @type = "REPORT"
                        | stats max(@memorySize / 1000 / 1000) as provisonedMemoryMB,
                                min(@maxMemoryUsed / 1000 / 1000) as smallestMemoryRequestMB,
                                avg(@maxMemoryUsed / 1000 / 1000) as avgMemoryUsedMB,
                                max(@maxMemoryUsed / 1000 / 1000) as maxMemoryUsedMB,
                                provisonedMemoryMB - maxMemoryUsedMB as overProvisionedMB,
                                avg(@duration), max(@duration), min(@duration) by bin(10m)' \
        --start-time $START_TIME \
        --end-time $END_TIME \
        --output text)
        # | xargs -I{} \
        sleep 5
    aws logs get-query-results --query-id "$query_id" --output json >> "$RESULT_FOLDER/${query_results_file}"
done



query_id=$(aws logs start-query \
    --log-group-names "$LOG_GROUP_NAMES" \
    --query-string 'fields @timestamp, @message, @logStream, @log
                    | sort @timestamp desc
                    | limit 20
                    | filter @type = "REPORT"
                    | stats max(@memorySize / 1000 / 1000) as provisonedMemoryMB,
                            min(@maxMemoryUsed / 1000 / 1000) as smallestMemoryRequestMB,
                            avg(@maxMemoryUsed / 1000 / 1000) as avgMemoryUsedMB,
                            max(@maxMemoryUsed / 1000 / 1000) as maxMemoryUsedMB,
                            provisonedMemoryMB - maxMemoryUsedMB as overProvisionedMB,
                            avg(@duration), max(@duration), min(@duration) by bin(5m)' \
    --start-time "$START_TIME" \
    --end-time "$END_TIME" \
    --output text)
        sleep 5
    aws logs get-query-results --query-id "$query_id" --output json >> "$RESULT_FOLDER/aggregratemetric.json"
    
 
# Remove the serverless deployment
serverless remove
