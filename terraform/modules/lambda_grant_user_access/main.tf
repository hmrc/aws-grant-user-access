locals {
  environment_variables = merge(var.environment_variables)
  ci_account_id         = "987972305662"
  ecr_repository_url    = "${local.ci_account_id}.dkr.ecr.eu-west-2.amazonaws.com/aws-grant-user-access"
}

module "lambda" {
  source = "../lambda"

  ecr_repository_url    = local.ecr_repository_url
  environment           = var.environment
  environment_variables = local.environment_variables
  lambda_function_name  = var.lambda_function_name
  ecr_image_tag         = "latest"
  policy_arns           = [aws_iam_policy.lambda_slack.arn]
  timeout_in_seconds    = var.timeout_in_seconds
  tags                  = merge(var.tags, { AllowCiDeploy = "true" })
  vpc_config            = var.vpc_config
  security_group_ids    = var.security_group_ids
}

resource "aws_iam_policy" "lambda_slack" {
  name   = "${var.lambda_function_name}-slack-role-policy"
  policy = data.aws_iam_policy_document.lambda_slack.json
}

data "aws_kms_alias" "aws_ssm" {
  name = "alias/aws/ssm"
}

data "aws_iam_policy_document" "lambda_slack" {
  statement {
    sid    = "GetSlackApiKeyParameter"
    effect = "Allow"

    actions = [
      "ssm:GetParameter",
    ]
    resources = [aws_ssm_parameter.slack_api_key.arn]
  }

  statement {
    sid    = "AllowKmsDecryptForSlackApiKey"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [data.aws_kms_alias.aws_ssm.target_key_arn]
  }
}
