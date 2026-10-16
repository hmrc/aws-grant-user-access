data "aws_secretsmanager_secret" "slack_api_key_secret" {
  arn = "arn:aws:secretsmanager:${var.region}:${var.slack_api_key_secret_account_id}:secret:service_accounts/slack_v2_api_key"
}
