data "aws_secretsmanager_secret" "slack_api_key_secret" {
  arn = "arn:aws:secretsmanager:${var.region}:${var.platsec_ci_account_id}:secret:service_accounts/slack_v2_api_key"
}

data "aws_kms_key" "slack_api_key_kms" {
  key_id = "arn:aws:kms:${var.region}:${var.platsec_ci_account_id}:alias/service_accounts_slack_v2_api_key"
}
