variable "project_prefix" {
  type = string
}

variable "function_name" {
  type = string
}

variable "handler" {
  type = string
}

variable "lambda_src_path" {
  type = string
}

variable "env_variables" {
  type    = map(string)
  default = {}
}

variable "policy_statements_json" {
  type = list(string)
}

variable "lambda_runtime" {
  type = string
}
