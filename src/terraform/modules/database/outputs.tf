output "dynamodb_table_name" {
  description = "DynamoDB Table Name"
  value       = aws_dynamodb_table.visitor_table.name
}

output "dynamodb_table_arn" {
    description = "DynamoDB Table ARN"
    value       = aws_dynamodb_table.visitor_table.arn
}