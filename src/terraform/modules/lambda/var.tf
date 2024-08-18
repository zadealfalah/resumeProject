variable "dynamodb_table_name" {
    description = "Name of the DynamoDB table to be used in the Lambda function"
    type        = string
}

variable "dynamodb_table_arn" {
    description = "ARN of the DynamODB table to be used in the Lambda function"
    type        = string
}