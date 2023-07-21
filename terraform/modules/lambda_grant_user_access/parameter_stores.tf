resource "aws_ssm_parameter" "grant_user_access" {
  name        = "/ecr/latest/${var.lambda_function_name}"
  description = "Latest ECR Image tag of ${var.lambda_function_name}"
  type        = "String"
  value       = "Initial value"

  lifecycle {
    ignore_changes = [value]
  }
}
