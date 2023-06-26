resource "aws_iam_role" "lambda" {
  assume_role_policy   = data.aws_iam_policy_document.lambda_assume_role.json
  name_prefix          = substr(var.lambda_function_name, 0, 38)
}

resource "aws_iam_role_policy" "lambda" {
  name   = "${var.lambda_function_name}-role-policy"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.lambda.json
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    effect = "Allow"
    principals {
      identifiers = [
        "lambda.amazonaws.com"
      ]
      type = "Service"
    }
  }
}

data "aws_iam_policy_document" "lambda" {
  statement {
    effect = "Allow"

    resources = [
      "*",
    ]

    actions = [
      "iam:CreatePolicy",
      "iam:TagPolicy",
      "iam:AttachUserPolicy",
    ]
  }
}

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
