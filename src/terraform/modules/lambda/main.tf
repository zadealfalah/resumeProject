# Zip the file itself, rename it and save in same folder
data "archive_file" "lambda" {
    type = "zip"
    source_file = "${path.module}/counter.py"
    output_path = "${path.module}/lambda_function_payload.zip"
}



resource "aws_lambda_function" "update_visitor_count" {
  filename = data.archive_file.lambda.output_path
  function_name = "view_counter"
  role = aws_iam_role.lambda_exec.arn
  handler = "counter.lambda_handler"
  runtime = "python3.10"
  timeout = 30
  source_code_hash = filebase64sha256(data.archive_file.lambda.output_path) 
  environment {
    variables = {
        DYNAMODB_TABLE_NAME = var.dynamodb_table_name
    }
  }
}


resource "aws_iam_role" "lambda_exec" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_dynamodb_policy" {
  name   = "lambda-dynamodb-policy"
  role   = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem"
        ]
        Effect   = "Allow"
        Resource = var.dynamodb_table_arn
      }
    ]
  })
}








# API gateway integration
resource "aws_api_gateway_rest_api" "visitor_count_api" {
  name = "VisitorCountAPI"
  description = "API Gateway to track visitor counts"
}

resource "aws_api_gateway_resource" "visitor" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  parent_id = aws_api_gateway_rest_api.visitor_count_api.root_resource_id
  path_part = "visitor"
}

resource "aws_api_gateway_method" "visitor_get" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor.id
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor.id
  http_method = aws_api_gateway_method.visitor_get.http_method
  type = "AWS_PROXY"
  integration_http_method = "POST"
  uri = aws_lambda_function.update_visitor_count.invoke_arn
}

resource "aws_api_gateway_deployment" "visitor_api_deployment" {
  depends_on = [ aws_api_gateway_integration.lambda_integration ]
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  stage_name = "prod"
}