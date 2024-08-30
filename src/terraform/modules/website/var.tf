variable "www_domain_name" {
  default = "www.zadealfalah.com"
}

variable "root_domain_name" {
  default = "zadealfalah.com"
}

variable "lambda_exec_role_name" {
  description = "The name of the IAM role used by my lambdas"
  type        = string
}

# variable "visitor_lambda_name" {
#     default = "visitor-counter-lambda"
# }

# variable "api_gateway_name" {
#     default = "visitor-counter-api"
# }

