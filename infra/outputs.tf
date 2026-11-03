output "bucket_name" {
  description = "Orders S3 bucket name."
  value       = aws_s3_bucket.orders.bucket
}

output "queue_url" {
  description = "Orders SQS queue URL."
  value       = aws_sqs_queue.orders.url
}

output "topic_arn" {
  description = "Orders SNS topic ARN."
  value       = aws_sns_topic.orders.arn
}

output "table_name" {
  description = "Orders DynamoDB table name."
  value       = aws_dynamodb_table.orders.name
}
