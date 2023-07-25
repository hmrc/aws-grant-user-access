data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_iam_policy_document" "ecr_pull_policy" {
  statement {
    sid    = "AllowPull"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      ]
    }
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]
  }
  statement {
    sid    = "AllowPullFromLambda"
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
    condition {
      test     = "StringLike"
      variable = "aws:sourceArn"
      values = [
        "arn:aws:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${var.lambda_function_name}"
      ]
    }
    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
    ]
  }
}
