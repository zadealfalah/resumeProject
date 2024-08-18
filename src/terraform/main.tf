terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
}


module "website" {
    source = "./modules/website"
}


module "database" {
    source = "./modules/database"
}

module "lambda" {
  source = "./modules/lambda"
  dynamodb_table_name = module.database.dynamodb_table_name
  dynamodb_table_arn = module.database.dynamodb_table_arn
}