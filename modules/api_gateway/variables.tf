variable "project_prefix" {
  type        = string
}
variable "cognito_userpool_arn" {
  type        = string
}
variable "cognito_userpool_id" {
  type        = string
}

variable "routes" {
  type = list(object({
    path       = string
    method     = string
    lambda_arn = string
  }))
}
