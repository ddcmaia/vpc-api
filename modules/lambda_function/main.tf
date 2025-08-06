# trust policy for Lambda execution role
data "aws_iam_policy_document" "lambda_trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_exec" {
  name               = "${var.project_prefix}-${var.function_name}-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json
}

# attach user-provided policy statements
resource "aws_iam_role_policy" "inline" {
  role   = aws_iam_role.lambda_exec.id
  policy = var.policy_statements_json[0]
}

# package source code
data "archive_file" "src_zip" {
  type        = "zip"
  source_dir  = var.lambda_src_path
  output_path = "${path.module}/tmp/${var.function_name}.zip"
}

# create Lambda function
resource "aws_lambda_function" "this" {
  function_name    = "${var.project_prefix}-${var.function_name}"
  runtime          = var.lambda_runtime
  handler          = var.handler
  filename         = data.archive_file.src_zip.output_path
  source_code_hash = data.archive_file.src_zip.output_base64sha256
  role             = aws_iam_role.lambda_exec.arn

  environment {
    variables = var.env_variables
  }
}

output "lambda_arn" { value = aws_lambda_function.this.arn }
