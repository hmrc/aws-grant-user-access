data "aws_iam_policy_document" "lambda_deploy" {
  statement {
    actions   = ["lambda:UpdateFunctionCode"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/AllowCiDeploy"
      values   = ["true"]
    }
  }

  statement {
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_deploy" {
  name_prefix = "ci-lambda-deploy"
  policy      = data.aws_iam_policy_document.lambda_deploy.json

  lifecycle {
    create_before_destroy = true
  }
}

module "lambda_deploy" {
  source = "../ci_role"

  role_name                     = "ci-lambda-deploy"
  role_policy_arn               = aws_iam_policy.lambda_deploy.arn
  ci_account_id                 = var.ci_account_id
  role_arn_secret_name          = "/shared/ci-lambda-deploy-role-arn"
  kms_override_policy_documents = [module.kms_key_policy_document.policy_document_json]
}
