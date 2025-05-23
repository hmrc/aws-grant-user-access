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
  policy_arns           = [aws_iam_policy.lambda_sns.arn]
  timeout_in_seconds    = var.timeout_in_seconds
  tags                  = var.tags
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
    ]
    resources = [data.aws_ssm_parameter.sns_topic_arn.value]
  }
}