module "ecr" {
  source = "../ecr"

  ecr_repository_name  = var.lambda_function_name
  lambda_function_name = var.lambda_function_name
}

locals {
  policy_arns           = var.sns_topic_arn == null ? [] : [aws_iam_policy.lambda_sns[0].arn]
  environment_variables = var.sns_topic_arn == null ? var.environment_variables : merge(var.environment_variables, { SNS_TOPIC_ARN : var.sns_topic_arn })
}

module "lambda" {
  source = "../lambda"

  ecr_repository_url    = module.ecr.ecr_repository_url
  environment           = var.environment
  environment_variables = local.environment_variables
  lambda_function_name  = var.lambda_function_name
  ecr_image_tag         = aws_ssm_parameter.grant_user_access.value
  policy_arns           = local.policy_arns
  timeout_in_seconds    = var.timeout_in_seconds
  tags                  = var.tags
}

resource "aws_iam_policy" "lambda_sns" {
  count  = var.sns_topic_arn != null ? 1 : 0
  name   = "${var.lambda_function_name}-sns-role-policy"
  policy = data.aws_iam_policy_document.lambda_sns[count.index].json
}

data "aws_iam_policy_document" "lambda_sns" {
  count = var.sns_topic_arn != null ? 1 : 0

  statement {
    sid    = "PublishToSnsTopic"
    effect = "Allow"

    actions = [
      "sns:Publish",
    ]
    resources = [var.sns_topic_arn]
  }

}