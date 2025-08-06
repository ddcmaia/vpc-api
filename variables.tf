variable "region" {
  type    = string
  default = "us-east-1" # AWS region
}

variable "project_prefix" {
  type    = string
  default = "vpc-api" # prefix for resource names
}

variable "lambda_runtime" {
  type    = string
  default = "python3.12" # runtime for Lambda functions
}
