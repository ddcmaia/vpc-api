
data "aws_region" "current" {} # needed for cognito issuer URL

# create HTTP API
resource "aws_apigatewayv2_api" "this" {
  name          = "${var.project_prefix}-http-api"
  protocol_type = "HTTP"
}

# jwt authorizer using cognito user pool
resource "aws_apigatewayv2_authorizer" "jwt" {
  name             = "cognito-jwt"
  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    issuer   = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${var.cognito_userpool_id}"
    audience = [var.cognito_userpool_id]
  }
}

# connect routes to Lambda functions
resource "aws_apigatewayv2_integration" "lambda" {
  for_each               = { for r in var.routes : "${r.method} ${r.path}" => r }
  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_uri        = each.value.lambda_arn
  payload_format_version = "2.0"
  timeout_milliseconds   = 29000
}

resource "aws_apigatewayv2_route" "route" {
  for_each      = { for r in var.routes : "${r.method} ${r.path}" => r }
  api_id        = aws_apigatewayv2_api.this.id
  route_key     = each.key
  target        = "integrations/${aws_apigatewayv2_integration.lambda[each.key].id}"
  authorizer_id = aws_apigatewayv2_authorizer.jwt.id
}

# allow API Gateway to invoke the Lambdas
resource "aws_lambda_permission" "allow_apigw" {
  for_each = { for r in var.routes : "${r.method} ${r.path}" => r }

  statement_id  = "AllowExecutionFromAPIGateway-${replace(replace(replace(replace(each.key, " ", "-"), "/", "-"), "{", ""), "}", "")}" # readable ID
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}

# send access logs to cloudWatch
resource "aws_cloudwatch_log_group" "api_access" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.this.id}_access"
  retention_in_days = 1
}

# deploy default stage with logging
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_access.arn
    format = jsonencode({
      requestId   = "$context.requestId"
      status      = "$context.status"
      integration = "$context.integrationStatus"
      routeKey    = "$context.routeKey"
      authorizer  = "$context.authorizer.error"
      latency     = "$context.responseLatency"
    })
  }
}

output "api_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}
