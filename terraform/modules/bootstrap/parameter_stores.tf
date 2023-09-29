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

resource "aws_ssm_parameter" "account_id" {
  for_each    = var.environment_account_ids
  name        = "/${each.key}/account_id"
  description = "AWS Account ID"
  type        = "String"
  value       = each.value
}

resource "aws_ssm_parameter" "grant_user_access_sns_topic" {
  name        = "/grant-user-access/sns_topic_arn"
  description = "Arn of SNS Topic grant-user-access-lambda publishes to"
  type        = "String"
  value       = var.grant_user_access_sns_topic_arn
}
