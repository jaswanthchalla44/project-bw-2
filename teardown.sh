#!/usr/bin/env bash
# Deletes exactly the four bwtest- resources created for this project, in us-east-1.
# Touches nothing else. Requires typing the confirmation phrase.
set -euo pipefail

REGION="us-east-1"
ACCOUNT_ID="339713010280"
BUCKET="bwtest-orders-339713010280"
QUEUE_URL="https://sqs.us-east-1.amazonaws.com/339713010280/bwtest-orders-queue"
TOPIC_ARN="arn:aws:sns:us-east-1:339713010280:bwtest-orders-topic"
TABLE="bwtest-orders-table"

# Refuse to run against any other AWS account.
CURRENT_ACCOUNT="$(aws sts get-caller-identity --query Account --output text)"
if [[ "$CURRENT_ACCOUNT" != "$ACCOUNT_ID" ]]; then
  echo "Refusing to run: current account is $CURRENT_ACCOUNT, expected $ACCOUNT_ID." >&2
  exit 1
fi

echo "This will PERMANENTLY DELETE in account $ACCOUNT_ID ($REGION):"
echo "  - S3 bucket:       s3://$BUCKET (all objects removed first)"
echo "  - SQS queue:       $QUEUE_URL"
echo "  - SNS topic:       $TOPIC_ARN"
echo "  - DynamoDB table:  $TABLE (with all data)"
echo
read -r -p "Type 'delete bwtest' to continue: " CONFIRM
if [[ "$CONFIRM" != "delete bwtest" ]]; then
  echo "Aborted. Nothing deleted."
  exit 1
fi

echo "Emptying and deleting S3 bucket $BUCKET..."
aws s3 rm "s3://$BUCKET" --recursive --region "$REGION"
aws s3api delete-bucket --bucket "$BUCKET" --region "$REGION"

echo "Deleting SQS queue..."
aws sqs delete-queue --queue-url "$QUEUE_URL" --region "$REGION"

echo "Deleting SNS topic..."
aws sns delete-topic --topic-arn "$TOPIC_ARN" --region "$REGION"

echo "Deleting DynamoDB table $TABLE..."
aws dynamodb delete-table --table-name "$TABLE" --region "$REGION" >/dev/null
aws dynamodb wait table-not-exists --table-name "$TABLE" --region "$REGION"

echo "Teardown complete."
