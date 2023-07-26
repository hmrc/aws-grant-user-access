resource "aws_ssm_parameter" "github_api_token" {
  name        = "/service_accounts/github_api_token"
  description = "GitHub API Token"
  type        = "SecureString"
  value       = "PLACEHOLDER - Value to be updated manually"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "access_log_bucket_id" {
  name        = "access_log_bucket_id"
  description = "Access log bucket id"
  type        = "String"
  value       = var.log_bucket_name
}
