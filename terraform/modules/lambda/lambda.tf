resource "aws_lambda_function" "this" {
  function_name                  = var.lambda_function_name
  role                           = aws_iam_role.lambda.arn
  memory_size                    = var.memory_size
  package_type                   = "Image"
  image_uri                      = "${var.ecr_repository_url}:${var.ecr_image_tag}"
  publish                        = true
  timeout                        = var.timeout
  reserved_concurrent_executions = var.reserved_concurrent_executions

  image_config {
    command = var.image_command
  }

  environment {
    variables = var.environment_variables
  }

  tags = var.tags
}

resource "aws_lambda_alias" "latest" {
  description      = "The latest version of the lambda"
  function_name    = aws_lambda_function.this.function_name
  function_version = "$LATEST"
  name             = "latest"
}
