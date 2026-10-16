module "lambda" {
  source = "../lambda"

  ecr_repository_url    = "${var.platsec_ci_account_id}.dkr.ecr.eu-west-2.amazonaws.com/aws-grant-user-access"
  environment           = var.environment
  lambda_function_name  = var.lambda_function_name
  ecr_image_tag         = "latest"
  policy_arns           = [aws_iam_policy.lambda_slack.arn]
  timeout_in_seconds    = var.timeout_in_seconds
  vpc_config            = var.vpc_config
  security_group_ids    = var.security_group_ids
  environment_variables = merge(var.environment_variables, { SLACK_API_SECRET_ARN = data.aws_secretsmanager_secret.slack_api_key_secret.arn })

  tags = merge(var.tags, { AllowCiDeploy = "true" })
}

resource "aws_iam_policy" "lambda_slack" {
  name   = "${var.lambda_function_name}-slack-role-policy"
  policy = data.aws_iam_policy_document.lambda_slack.json
}

data "aws_iam_policy_document" "lambda_slack" {

  statement {
    sid    = "AllowCrossAccountAccessToSlackApiKey"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [data.aws_secretsmanager_secret.slack_api_key_secret.arn]
  }

  statement {
    sid    = "AllowCrossAccountAccessToSlackApiKeyKms"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]
    resources = [data.aws_kms_key.slack_api_key_kms.arn]
  }
}
