
data "aws_iam_policy_document" "codepipeline_assume_role" {
  statement {
    principals {
      identifiers = ["codepipeline.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

data "aws_iam_policy_document" "codepipeline_policy" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObjectAcl",
      "s3:PutObject",
      "s3:GetObjectVersion",
      "s3:GetObject",
      "s3:GetBucketVersioning"
    ]
    resources = [
      "${module.codepipeline_bucket.arn}/*/source_out/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild"
    ]

    resources = [
      "arn:aws:codebuild:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:project/${local.pipeline_name}*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Encrypt",
      "kms:DescribeKey",
      "kms:Decrypt",
    ]
    resources = [
      module.codepipeline_bucket.kms_key_arn
    ]
  }
}

resource "aws_iam_policy" "codepipeline_policy" {
  name_prefix = substr(local.pipeline_name, 0, 32)
  description = "${local.pipeline_name} CodePipeline"
  policy      = data.aws_iam_policy_document.codepipeline_policy.json

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Pipeline = local.pipeline_name
  }
}

resource "aws_iam_role" "codepipeline_role" {
  name_prefix         = substr(local.pipeline_name, 0, 32)
  description         = "${local.pipeline_name} CodePipeline"
  assume_role_policy  = data.aws_iam_policy_document.codepipeline_assume_role.json
  managed_policy_arns = [aws_iam_policy.codepipeline_policy.arn]

  tags = {
    Pipeline = local.pipeline_name
  }
}

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    principals {
      identifiers = ["codebuild.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

data "aws_iam_policy_document" "build_core" {

  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [
      module.codepipeline_bucket.kms_key_arn
    ]
  }

  statement {
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:GetBucketVersioning",
    ]
    resources = [
      "${module.codepipeline_bucket.arn}/*/source_out/*",
      "${module.codepipeline_bucket.arn}/*/build_outp/*",
    ]
  }
}

resource "aws_iam_policy" "build_core" {
  name_prefix = substr(local.pipeline_name, 0, 32)
  description = "${local.pipeline_name} build"
  policy      = data.aws_iam_policy_document.build_core.json

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Pipeline = local.pipeline_name
  }
}
