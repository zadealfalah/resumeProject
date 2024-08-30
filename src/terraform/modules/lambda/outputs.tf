# Can pipe to config or env, etc. to dynamically update .js file if it changes.  
// Output for API Gateway URL
# output "api_gw_url" {
#   value = "${aws_api_gateway_deployment.deploy_api.invoke_url}"
# }

output "visitor_lambda_function_name" {
  description = "Name of the Lambda Function for visitor counting"
  value       = aws_lambda_function.update_visitor_count.function_name
}

output "lambda_exec_role_name" {
  value = aws_iam_role.lambda_exec.name
}


# # Should use this in my CICD to change the counter.py URL
# output "apigw_base_url" {
#   description = "Base URL for API Gateway stage"
#   value = aws_apigatewayv2_stage.lambda.invoke_url
# }