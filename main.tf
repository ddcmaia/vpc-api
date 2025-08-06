terraform {
  required_version = ">= 1.12"

  backend "s3" {
    bucket  = "tests-maia"
    key     = "terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }

  required_providers {
    aws     = { source = "hashicorp/aws", version = "~> 5.0" }
    archive = { source = "hashicorp/archive", version = "~> 2.4" }
  }
}

provider "aws" {
  region = var.region # default AWS region
}

# cognito user pool for authentication
module "cognito" {
  source         = "./modules/cognito"
  project_prefix = var.project_prefix
}

# dynamoDB table to store VPC metadata
module "ddb" {
  source         = "./modules/dynamodb"
  project_prefix = var.project_prefix
  table_name     = "VpcMetadata"
  hash_key       = "vpc_id"
}

# lambda function that creates VPCs
module "create_vpc_fn" {
  source          = "./modules/lambda_function"
  project_prefix  = var.project_prefix
  function_name   = "create-vpc"
  handler         = "main.handler"
  lambda_src_path = "${path.module}/lambda/create_vpc"
  lambda_runtime  = var.lambda_runtime
  env_variables = {
    VPC_TABLE = module.ddb.table_name
  }
  policy_statements_json = [jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Action = ["logs:*"], Effect = "Allow", Resource = "arn:aws:logs:*:*:*" },
      { Action = ["ec2:*"], Effect = "Allow", Resource = "*" }, # tighten later
      { Action = ["dynamodb:PutItem"], Effect = "Allow", Resource = module.ddb.table_arn }
    ]
  })]
}

# lambda function that retrieves VPC info
module "get_vpc_fn" {
  source          = "./modules/lambda_function"
  project_prefix  = var.project_prefix
  function_name   = "get-vpc"
  handler         = "main.handler"
  lambda_src_path = "${path.module}/lambda/get_vpc"
  lambda_runtime  = var.lambda_runtime
  env_variables = {
    VPC_TABLE = module.ddb.table_name
  }
  policy_statements_json = [jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Action = ["logs:*"], Effect = "Allow", Resource = "arn:aws:logs:*:*:*" },
      { Action = ["dynamodb:GetItem"], Effect = "Allow", Resource = module.ddb.table_arn }
    ]
  })]
}

# HTTP API wired to our Lambdas and protected by Cognito
module "api" {
  source               = "./modules/api_gateway"
  project_prefix       = var.project_prefix
  cognito_userpool_id  = module.cognito.user_pool_id
  cognito_userpool_arn = module.cognito.user_pool_arn
  routes = [
    { path = "/vpcs", method = "POST", lambda_arn = module.create_vpc_fn.lambda_arn },
    { path = "/vpcs/{id}", method = "GET", lambda_arn = module.get_vpc_fn.lambda_arn }
  ]
}

# expose useful values after deployment
output "api_url" { value = module.api.api_url }
output "user_pool_id" { value = module.cognito.user_pool_id }
output "cognito_app_client_id" { value = module.cognito.app_client_id }
output "ddb_table" { value = module.ddb.table_name }
