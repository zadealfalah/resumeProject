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

# Trying explicit declaration of invokation instead of blanket principal below
# resource "aws_lambda_permission" "allow_api_gateway" {
#     statement_id = "AllowExecutionFromAPIGateway"
#     action = "lambda:InvokeFunction"
#     function_name = aws_lambda_function.update_visitor_count.function_name
#     principal = "apigateway.amazonaws.com"
# }


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






# API Gateway to track visitor counts
resource "aws_api_gateway_rest_api" "visitor_count_api" {
  name        = "VisitorCountAPI"
  description = "API Gateway to track visitor counts"
}

resource "aws_api_gateway_resource" "visitor" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  parent_id   = aws_api_gateway_rest_api.visitor_count_api.root_resource_id
  path_part   = "visitor"
}



resource "aws_api_gateway_method" "options_method" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}


resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor.id
  http_method = aws_api_gateway_method.options_method.http_method
  type = "MOCK"
#   depends_on = [ aws_api_gateway_method.options_method ]
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id   = aws_api_gateway_resource.visitor.id
  http_method   = aws_api_gateway_method.options_method.http_method
  status_code   = aws_api_gateway_method_response.options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}


resource "aws_api_gateway_method" "cors_method" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method_response" "cors_method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor.id
  http_method = aws_api_gateway_method.cors_method.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
#   depends_on = [ aws_api_gateway_method.cors_method ]
}

resource "aws_api_gateway_integration" "integration" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor.id
  http_method = aws_api_gateway_method.cors_method.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.update_visitor_count.invoke_arn
#   depends_on = [ aws_api_gateway_method.cors_method, aws_lambda_function.update_visitor_count ]
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  stage_name = "prod"
  depends_on = [ 
      aws_api_gateway_integration.integration,
      aws_api_gateway_integration.get_integration,
      aws_api_gateway_integration.options_integration
    ]
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}


resource "aws_lambda_permission" "allow_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update_visitor_count.arn
  principal = "apigateway.amazonaws.com"
  source_arn = "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${aws_api_gateway_rest_api.visitor_count_api.id}/*/*/visitor"
}





resource "aws_api_gateway_method" "visitor_get" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor.id
  http_method = "GET"
  authorization = "NONE"
}



resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id             = aws_api_gateway_resource.visitor.id
  http_method             = aws_api_gateway_method.visitor_get.http_method
  integration_http_method = "GET"  
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.update_visitor_count.invoke_arn
}



resource "aws_api_gateway_method_response" "get_method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id = aws_api_gateway_resource.visitor.id
  http_method = aws_api_gateway_method.visitor_get.http_method
  status_code = "200"
  
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = true
  }
}

resource "aws_api_gateway_integration_response" "get_integration_response" {
  rest_api_id   = aws_api_gateway_rest_api.visitor_count_api.id
  resource_id   = aws_api_gateway_resource.visitor.id
  http_method   = aws_api_gateway_method.visitor_get.http_method
  status_code   = aws_api_gateway_method_response.get_method_response_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"  
    }
}



# # API gateway integration
# resource "aws_api_gateway_rest_api" "visitor_count_api" {
#   name = "VisitorCountAPI"
#   description = "API Gateway to track visitor counts"
# }

# resource "aws_api_gateway_resource" "visitor" {
#   rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
#   parent_id = aws_api_gateway_rest_api.visitor_count_api.root_resource_id
#   path_part = "visitor"
# }

# resource "aws_api_gateway_method" "visitor_get" {
#   rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
#   resource_id = aws_api_gateway_resource.visitor.id
#   http_method = "GET"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "lambda_integration" {
#   rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
#   resource_id = aws_api_gateway_resource.visitor.id
#   http_method = aws_api_gateway_method.visitor_get.http_method
#   type = "AWS_PROXY"
#   integration_http_method = "POST"
#   uri = aws_lambda_function.update_visitor_count.invoke_arn
# }

# resource "aws_api_gateway_deployment" "visitor_api_deployment" {
#   depends_on = [ aws_api_gateway_integration.lambda_integration ]
#   rest_api_id = aws_api_gateway_rest_api.visitor_count_api.id
#   stage_name = "prod"
# }