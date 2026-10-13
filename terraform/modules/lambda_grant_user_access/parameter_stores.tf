resource "aws_ssm_parameter" "slack_api_key" {
  name        = "/service_accounts/slack_v2_api_key"
  description = "Slack API Key for sending notifications from ${var.lambda_function_name}"
  type        = "SecureString"
  value       = "latest"

  lifecycle {
    ignore_changes = [value]
  }
}
