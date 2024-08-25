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

# Allow Lambda to write to cloudwatch
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Cloudwatch log group
resource "aws_cloudwatch_log_group" "visitor_counter_logging" {
  name = "/lambda/${aws_lambda_function.update_visitor_count.function_name}"
  retention_in_days = 30
}


data "aws_region" "current" {}

data "aws_caller_identity" "current" {}


resource "aws_api_gateway_rest_api" "visitor_api" {
  name        = "visitor_api"
  description = "Visitor counter API"
}

resource "aws_api_gateway_resource" "visitor_resource" {
  rest_api_id = aws_api_gateway_rest_api.visitor_api.id
  parent_id   = aws_api_gateway_rest_api.visitor_api.root_resource_id
  path_part   = "verify-json"
}

resource "aws_api_gateway_method" "get_method" {
  rest_api_id = aws_api_gateway_rest_api.visitor_api.id
  resource_id   = aws_api_gateway_resource.visitor_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.visitor_api.id
  resource_id             = aws_api_gateway_resource.visitor_resource.id
  http_method             = aws_api_gateway_method.get_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.update_visitor_count.invoke_arn
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_visitor_count.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.visitor_api.id}/*/${aws_api_gateway_method.get_method.http_method}${aws_api_gateway_resource.visitor_resource.path}"
}

resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.visitor_api.id
  resource_id = aws_api_gateway_resource.visitor_resource.id
  http_method = aws_api_gateway_method.get_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.visitor_api.id
  resource_id = aws_api_gateway_resource.visitor_resource.id
  http_method = aws_api_gateway_method.get_method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code
#   response_templates = {
#     "application/json" = 
#   }
}

# Enable CORS
resource "aws_api_gateway_method" "_" {
  rest_api_id = aws_api_gateway_rest_api.visitor_api.id
  resource_id   = aws_api_gateway_resource.visitor_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}
resource "aws_api_gateway_integration" "_" {
  rest_api_id = aws_api_gateway_rest_api.visitor_api.id
  resource_id   = aws_api_gateway_resource.visitor_resource.id
  http_method = aws_api_gateway_method._.http_method
  content_handling = "CONVERT_TO_TEXT"
  type = "MOCK"
  request_templates = {
    "application/josn" = "{ \"statusCode\": 200 }"
  }
}
resource "aws_api_gateway_integration_response" "_" {
  rest_api_id = aws_api_gateway_rest_api.visitor_api.id
  resource_id   = aws_api_gateway_resource.visitor_resource.id
  http_method = aws_api_gateway_method._.http_method
  status_code = 200
  response_parameters = local.integration_response_parameters
  depends_on = [ 
    aws_api_gateway_integration._,
    aws_api_gateway_method_response._
   ]
}

resource "aws_api_gateway_method_response" "_" {
  rest_api_id = aws_api_gateway_rest_api.visitor_api.id
  resource_id   = aws_api_gateway_resource.visitor_resource.id
  http_method = aws_api_gateway_method._.http_method
  status_code = 200
  response_parameters = local.method_response_parameters
  response_models = {
    "application/json" = "Empty"
  }
  depends_on = [ aws_api_gateway_method._ ]
}

# Deploy the apigw
resource "aws_api_gateway_deployment" "visitor_deployment" {
  depends_on = [ aws_api_gateway_integration.integration ]
  rest_api_id = aws_api_gateway_rest_api.visitor_api.id
  stage_name = "test"
}




# # API gateway integration
# resource "aws_apigatewayv2_api" "lambda_gateway" {
#   name = "serverless_lambda_gw"
#   protocol_type = "HTTP" # May want to switch this to HTTPS
# }

# resource "aws_apigatewayv2_stage" "lambda" {
#   api_id = aws_apigatewayv2_api.lambda_gateway.id
#   name = "serverless_lambda_stage"
#   auto_deploy = true
#   access_log_settings {
#       destination_arn = aws_cloudwatch_log_group.visitor_counter_logging.arn

#         format = jsonencode({
#         requestId               = "$context.requestId"
#         sourceIp                = "$context.identity.sourceIp"
#         requestTime             = "$context.requestTime"
#         protocol                = "$context.protocol"
#         httpMethod              = "$context.httpMethod"
#         resourcePath            = "$context.resourcePath"
#         routeKey                = "$context.routeKey"
#         status                  = "$context.status"
#         responseLength          = "$context.responseLength"
#         integrationErrorMessage = "$context.integrationErrorMessage"
#         }
#         )
#     }
#     }

# resource "aws_apigatewayv2_integration" "visitor_counter" {
#   api_id = aws_apigatewayv2_api.lambda_gateway.id
#   integration_uri = aws_lambda_function.update_visitor_count.invoke_arn
#   integration_type = "AWS_PROXY"
#   integration_method = "POST"
# }

# resource "aws_apigatewayv2_route" "visitor_counter" {
#   api_id = aws_apigatewayv2_api.lambda_gateway.id
#   route_key = "GET /counter"
#   target = "integrations/${aws_apigatewayv2_integration.visitor_counter.id}"
# }

# resource "aws_cloudwatch_log_group" "api_gw" {
#   name = "/api_gw/${aws_apigatewayv2_api.lambda_gateway.name}"
#   retention_in_days = 30
# }

# resource "aws_lambda_permission" "api_gw" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.update_visitor_count.function_name
#   principal     = "apigateway.amazonaws.com"

#   source_arn = "${aws_apigatewayv2_api.lambda_gateway.execution_arn}/*/*"
# }