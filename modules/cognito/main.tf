# cognito user pool for API users
resource "aws_cognito_user_pool" "this" {
  name = "${var.project_prefix}-users"
}

# application client to perform auth flows
resource "aws_cognito_user_pool_client" "app" {
  name         = "${var.project_prefix}-client"
  user_pool_id = aws_cognito_user_pool.this.id
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

output "user_pool_id" { value = aws_cognito_user_pool.this.id }
output "user_pool_arn" { value = aws_cognito_user_pool.this.arn }
output "app_client_id" { value = aws_cognito_user_pool_client.app.id }
