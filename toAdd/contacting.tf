# Contact page resources for aws including SES, lambda, and api gateway

# Zip up file and rename it in same folder
data "archive_file" "contact_lambda" {
    type = "zip"
    source_file = "${path.module}/contact.py"
    output_path = "${path.module}/contact_payload.zip"
}

# Lambda function definition
resource "aws_lambda_function" "contact_lambda" {
  filename = data.archive_file.contact_lambda.output_path
  function_name = "contact"
  role = aws_iam_role.lambda_exec.arn
  handler = "contact.lambda_handler"
  runtime = "python3.10"
  timeout = 30
  source_code_hash = filebase64sha256(data.archive_file.contact_lambda.output_path)
  environment {
    variables = {
      RECIPIENT_EMAIL = "zadealfalah@gmail.com" # Send emails to main email by default
    }
  }
}

# Add SES policy to lambda exec role
resource "aws_iam_policy_attachment" "ses_policy" {
  name       = "ses_policy_attachment"
  roles      = [aws_iam_role.lambda_exec.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSESFullAccess"
}

# API GW definitions
resource "aws_api_gateway_rest_api" "contact_api" {
  name = "contact_form_api"
  description = "API for website contact form"
}

resource "aws_api_gateway_resource" "contact_resource" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  parent_id = aws_api_gateway_rest_api.contact_api.root_resource_id
  path_part = "contact"
}

resource "aws_api_gateway_method" "contact_post_method" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.contact_resource.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "contact_lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id = aws_api_gateway_resource.contact_resource.id
  http_method = aws_api_gateway_method.contact_post_method.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.contact_lambda.invoke_arn
}

resource "aws_api_gateway_deployment" "contact_deployment" {
  depends_on = [ aws_api_gateway_integration.contact_lambda_integration ]
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  stage_name = "prod"
}

resource "aws_lambda_permission" "contact_api_permission" {
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.contact_lambda.function_name
  principal = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.contact_api.id}/*/${aws_api_gateway_method.contact_post_method.http_method}${aws_api_gateway_resource.contact_resource.path}"
}



# CORS

resource "aws_api_gateway_method" "contact_method" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id   = aws_api_gateway_resource.contact_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "contact_integration" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id   = aws_api_gateway_resource.contact_resource.id
  http_method = aws_api_gateway_method.contact_method.http_method
  content_handling = "CONVERT_TO_TEXT"
  type = "MOCK"
  request_templates = {
    "application/josn" = "{ \"statusCode\": 200 }"
  }
}
resource "aws_api_gateway_integration_response" "cors_integration_response" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id   = aws_api_gateway_resource.contact_resource.id
  http_method = aws_api_gateway_method.contact_method.http_method
  status_code = 200
  response_parameters = local.integration_response_parameters
  depends_on = [ 
    aws_api_gateway_integration.contact_integration,
    aws_api_gateway_method_response.contact_response
   ]
}

resource "aws_api_gateway_method_response" "contact_response" {
  rest_api_id = aws_api_gateway_rest_api.contact_api.id
  resource_id   = aws_api_gateway_resource.contact_resource.id
  http_method = aws_api_gateway_method.contact_method.http_method
  status_code = 200
  response_parameters = local.method_response_parameters
  response_models = {
    "application/json" = "Empty"
  }
  depends_on = [ aws_api_gateway_method.contact_method ]
}