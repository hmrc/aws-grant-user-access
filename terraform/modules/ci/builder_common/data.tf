data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}

data "aws_ssm_parameter" "github_api_token" {
  name = "/service_accounts/github_api_token"
}

data "aws_ssm_parameter" "access_log_bucket_id" {
  name = "access_log_bucket_id"
}
