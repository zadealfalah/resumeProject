# output "website_domain_name" {
#   description = "Website URL (HTTPS)"
#   value       = module.website.website_domain_name
# }

output "website_endpoint" {
  description = "S3 hosting URL (HTTP)"
  value       = module.website.website_endpoint
}

output "dynamodb_table_name" {
  description = "DynamoDB Table Name"
  value       = module.database.dynamodb_table_name
}