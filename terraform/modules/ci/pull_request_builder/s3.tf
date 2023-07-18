locals {
  bucket_name          = "ci-${substr(var.project_name, 0, 32)}"
  access_log_bucket_id = data.aws_ssm_parameter.access_logs_bucket_id.value
}

module "pr_builder_bucket" {
  source         = "hmrc/s3-bucket-core/aws"
  version        = "1.0.0"
  bucket_name    = local.bucket_name
  force_destroy  = true
  kms_key_policy = null

  data_expiry      = "90-days"
  data_sensitivity = "low"

  log_bucket_id = local.access_log_bucket_id
  tags = {
    codebuild_project = var.project_name
  }
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = module.pr_builder_bucket.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:*",
    ]
    resources = [
      module.pr_builder_bucket.arn,
      "${module.pr_builder_bucket.arn}/*",
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid    = "DenyAdminActivities"
    effect = "Deny"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:DeleteBucket*",
      "s3:GetAccelerateConfiguration",
      "s3:GetAnalyticsConfiguration",
      "s3:GetInventoryConfiguration",
      "s3:GetMetricsConfiguration",
      "s3:GetReplicationConfiguration",
      "s3:PutAccelerateConfiguration",
      "s3:PutAnalyticsConfiguration",
      "s3:PutBucket*",
      "s3:PutEncryptionConfiguration",
      "s3:PutInventoryConfiguration",
      "s3:PutLifecycleConfiguration",
      "s3:PutMetricsConfiguration",
      "s3:PutReplicationConfiguration",
    ]
    resources = [module.pr_builder_bucket.arn]
    condition {
      test     = "StringNotLike"
      variable = "aws:PrincipalArn"
      values   = [for k, v in var.project_assume_roles : v]
    }
  }
}
