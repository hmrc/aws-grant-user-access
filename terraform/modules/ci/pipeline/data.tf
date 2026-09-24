data "aws_ssm_parameter" "github_api_token" {
  name = "/service_accounts/github_api_token"
}

data "aws_ssm_parameter" "access_log_bucket_id" {
  name = "access_log_bucket_id"
}

data "aws_caller_identity" "current" {}

data "aws_codestarconnections_connection" "this" {
  name = var.codeconnection_name
}
