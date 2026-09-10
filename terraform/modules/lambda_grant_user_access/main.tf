locals {
  environment_variables = merge(var.environment_variables, { SNS_TOPIC_ARN : data.aws_ssm_parameter.sns_topic_arn.value })
}

data "aws_ssm_parameter" "sns_topic_arn" {
  name = var.sns_topic_parameter_store_name
}

module "ecr" {
  source = "../ecr"

  ecr_repository_name  = var.lambda_function_name
  lambda_function_name = var.lambda_function_name
}

module "lambda" {
  source = "../lambda"

  ecr_repository_url    = module.ecr.ecr_repository_url
  environment           = var.environment
  environment_variables = local.environment_variables
  lambda_function_name  = var.lambda_function_name
  ecr_image_tag         = aws_ssm_parameter.grant_user_access.value
  policy_arns           = [aws_iam_policy.lambda_sns.arn, aws_iam_policy.lambda_slack.arn]
  timeout_in_seconds    = var.timeout_in_seconds
  tags                  = var.tags
  vpc_config            = var.vpc_config
  security_group_ids    = var.security_group_ids
}

resource "aws_iam_policy" "lambda_sns" {
  name   = "${var.lambda_function_name}-sns-role-policy"
  policy = data.aws_iam_policy_document.lambda_sns.json
}

data "aws_iam_policy_document" "lambda_sns" {

  statement {
    sid    = "PublishToSnsTopic"
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]
    resources = [data.aws_ssm_parameter.sns_topic_arn.value]
  }

  statement {
    sid    = "AllowKmsGenerateDataKey"
    effect = "Allow"

    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt",
    ]
    resources = ["*"]
    condition {
      test     = "ForAnyValue:StringLike"
      variable = "kms:ResourceAliases"
      values = [
        "alias/sns_topic_kms_*"
      ]
    }
  }
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
