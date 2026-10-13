module "share_role_arn" {
  source                    = "git::https://github.com/hmrc/public-artefact-store.git//modules/share_secret?ref=867799d8c5b4191636c9fc6b09a42e06acdd7746"
  secret_name               = var.role_arn_secret_name
  secret_value              = aws_iam_role.role.arn
  allowed_account_ids       = [var.ci_account_id]
  override_policy_documents = var.kms_override_policy_documents
  tags                      = {}
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    principals {
      identifiers = ["arn:aws:iam::${var.ci_account_id}:root"]
      type        = "AWS"
    }

    actions = [
      "sts:AssumeRole"
    ]

    condition {
      test     = "StringLike"
      variable = "aws:userid"
      values   = ["*:AWSCodeBuild-*"]
    }
  }
}

resource "aws_iam_role" "role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

resource "aws_iam_role_policy_attachments_exclusive" "policy_attachment" {
  role_name   = aws_iam_role.role.name
  policy_arns = [var.role_policy_arn]
}
