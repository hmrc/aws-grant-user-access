locals {
  bucket_name              = "ci-${substr(local.pipeline_name, 0, 32)}"
  current_provisioner_role = data.aws_iam_session_context.current.issuer_arn
  admins                   = sort(distinct(concat(var.admin_roles, [local.current_provisioner_role])))
}

module "codepipeline_bucket" {
  source         = "hmrc/s3-bucket-core/aws"
  version        = "1.0.0"
  bucket_name    = local.bucket_name
  force_destroy  = true
  kms_key_policy = null

  data_expiry      = "90-days"
  data_sensitivity = "low"

  log_bucket_id = var.access_log_bucket_id
  tags = {
    Pipeline = local.pipeline_name
  }
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = module.codepipeline_bucket.id
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
      module.codepipeline_bucket.arn,
      "${module.codepipeline_bucket.arn}/*",
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
    resources = [module.codepipeline_bucket.arn]
    condition {
      test     = "StringNotLike"
      variable = "aws:PrincipalArn"
      values   = local.admins
    }
  }

  statement {
    sid    = "AllowProwlerScannerReadOnlyAccess"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketPolicy",
      "s3:GetBucketPolicyStatus",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:GetEncryptionConfiguration",
      "s3:GetBucketLogging",
      "s3:GetBucketPublicAccessBlock",
      "s3:GetBucketOwnershipControls",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetBucketNotification",
      "s3:GetLifecycleConfiguration",
      "s3:GetReplicationConfiguration",
      "s3:GetAccelerateConfiguration"
    ]
    resources = [
      module.codepipeline_bucket.arn,
      "${module.codepipeline_bucket.arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/RoleProwlerScanner"]
    }
  }
}
