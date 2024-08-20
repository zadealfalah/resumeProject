# Can pipe to config or env, etc. to dynamically update .js file if it changes.  
// Output for API Gateway URL
# output "api_gw_url" {
#   value = "${aws_api_gateway_deployment.deploy_api.invoke_url}"
# }