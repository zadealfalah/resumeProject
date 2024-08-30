resource "aws_dynamodb_table" "visitor_table" {
  name         = var.dynamodb_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id" # Primary key 
  #   range_key         =  # Sort key, unneeded for now. could use timestamp when expanding project

  attribute {
    name = "id"
    type = "S" # String type
  }
}


# Below was a solution that isn't needed
# Instead we use the counter.py itself to fill the first row if it doesn't exist

# data "aws_region" "current" {}

# # Null resource to run a local-exec provisioner
# resource "null_resource" "initialize_table" {
#   provisioner "local-exec" {
#     command = <<EOT
#       aws dynamodb put-item \
#         --region ${data.aws_region.current.name} \
#         --table-name ${var.dynamodb_table_name} \
#         --item '{"id": {"S": "0"}, "views": {"N": "0"}}'
#     EOT
#     environment = {
#       AWS_DEFAULT_REGION = data.aws_region.current.name
#     }
#   }
# }