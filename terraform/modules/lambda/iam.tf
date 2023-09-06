resource "aws_iam_role" "lambda" {
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  name_prefix        = substr(var.lambda_function_name, 0, 38)
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
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/Lambda/GrantUserAccess/*",
    ]

    actions = [
      "iam:AttachUserPolicy",
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:DetachUserPolicy",
      "iam:GetPolicy",
      "iam:ListEntitiesForPolicy",
      "iam:ListPolicyTags",
      "iam:ListPolicies",
      "iam:ListPolicyVersions",
      "iam:TagPolicy",
    ]
  }

  statement {
    sid = "Logging"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}
