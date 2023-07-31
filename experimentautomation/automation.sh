#!/bin/bash
# Set the default name for the CloudFormation template
CFTEMPLATENAME="apigatewaycf"

CFFOLDER="cloudformationtemplates"



# Create the result folder
RESULT_FOLDER="foldername"
mkdir "$RESULT_FOLDER"

# Set AWS region and profile
export AWS_DEFAULT_REGION=eu-central-1

# Deploy the CloudFormation stack
STACK_NAME="container1web-stack"
TEMPLATE_FILE="./$CFFOLDER/${CFTEMPLATENAME}.yml"
aws cloudformation deploy \
--stack-name $STACK_NAME \
--template-file $TEMPLATE_FILE \
--capabilities CAPABILITY_IAM

START_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
epoch_start_time=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$START_TIME" "+%s")

load_balancer_arn=$(aws elbv2 describe-load-balancers --names container1-loadbalancer --query "LoadBalancers[].LoadBalancerArn" --output text)
target_group_arn=$(aws elbv2 describe-target-groups --names loadbalancer1-targetgroup --query "TargetGroups[].TargetGroupArn" --output text)

url=$(aws elbv2 describe-load-balancers --load-balancer-arns $load_balancer_arn --query "LoadBalancers[].DNSName" --output text)
API_ENDPOINT="http://${url}"
echo "API endpoint URL: $API_ENDPOINT"


# Run Locust load test
LOCUSTFILE="locustfile.py"
USERS=50
HATCH_RATE=1
DURATION=3600

LOCUSTRESULT_FILE=containerlocustresult
# sleep 3600
locust -f $LOCUSTFILE --headless -u $USERS -r $HATCH_RATE -t $DURATION --host="$API_ENDPOINT" --csv="$RESULT_FOLDER/${LOCUSTRESULT_FILE}"

END_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)
epoch_end_time=$(date -u -j -f "%Y-%m-%dT%H:%M:%SZ" "$END_TIME" "+%s")
#output the resource usage metric to results folder
# Define variables
CONTAINER_NAME="container1webapi"
CLUSTER_NAME="container1webcluster"
SERVICE_NAME="container1webservice"

LOG_GROUP_NAME="container1webapilog"
LOG_GROUP_PREFIX="ccf-admin"


# Export CPU and memory utilization metrics to a file
aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ClusterName,Value=$CLUSTER_NAME Name=ServiceName,Value=$SERVICE_NAME --start-time $START_TIME --end-time $END_TIME --period 300 --statistics Average --output json >> "$RESULT_FOLDER/cpumetrics.json"
aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name MemoryUtilization --dimensions Name=ClusterName,Value=$CLUSTER_NAME Name=ServiceName,Value=$SERVICE_NAME --start-time $START_TIME --end-time $END_TIME --period 300 --statistics Average --output json >> "$RESULT_FOLDER/memorymetrics.json"
# aws cloudwatch get-metric-statistics --namespace AWS/ApplicationELB --metric-name TargetResponseTime --dimensions Name=LoadBalancer,Value=$load_balancer_arn Name=TargetGroup,Value=$target_group_arn --start-time $START_TIME --end-time $END_TIME --period 300 --statistics Average --output json >> "$RESULT_FOLDER/responsetimemetrics.json"

task_arns=$(aws ecs list-tasks --cluster "$CLUSTER_NAME" --query 'taskArns[]' --output text >> "$RESULT_FOLDER/tasks.json")
for task_arn in "${task_arns[@]}"; do
    task_id="${task_arn##*/}"
    log_stream_name="$LOG_GROUP_PREFIX/$CONTAINER_NAME/$task_id"
    response_times=$(aws logs filter-log-events --log-group-name "$LOG_GROUP_NAME" --log-stream-names "$log_stream_name" --start-time $epoch_start_time --end-time $epoch_end_time --output json >> "$RESULT_FOLDER/logs.json")
done

# Delete the CloudFormation stack
aws cloudformation delete-stack \
--stack-name $STACK_NAME
aws cloudformation wait stack-delete-complete \
--stack-name $STACK_NAME
