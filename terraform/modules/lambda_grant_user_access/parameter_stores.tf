resource "aws_ssm_parameter" "grant_user_access" {
  name        = "${var.lambda_function_name}-image-tag"
  description = "Latest ECR Image tag of ${var.lambda_function_name}"
  type        = "String"
  value       = "Initial value"

  lifecycle {
    ignore_changes = [value]
  }
}
