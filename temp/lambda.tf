resource "aws_lambda_function" "visitor_counter_lambda" {
  function_name = var.visitor_lambda_name
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  filename      = "./lambda/lambda_function.zip"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.visitor_counter.name
    }
  }
}