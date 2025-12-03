locals {
  bucket_name          = "ci-${substr(var.project_name, 0, 60)}"
  access_log_bucket_id = data.aws_ssm_parameter.access_log_bucket_id.value

  current_provisioner_role = data.aws_iam_session_context.current.issuer_arn
  project_assume_roles     = [for k, v in var.project_assume_roles : v]
  admins                   = sort(distinct(concat(local.project_assume_roles, [local.current_provisioner_role])))
}

module "builder_bucket" {
  source         = "hmrc/s3-bucket-core/aws"
  version        = "3.1.0"
  bucket_name    = local.bucket_name
  force_destroy  = true
  kms_key_policy = data.aws_iam_policy_document.bucket_kms_policy.json

  data_expiry      = "90-days"
  data_sensitivity = "low"

  log_bucket_id = local.access_log_bucket_id
  tags = {
    codebuild_project = var.project_name
  }
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = module.builder_bucket.id
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
      module.builder_bucket.arn,
      "${module.builder_bucket.arn}/*",
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
      "s3:PutAccelerateConfiguration",
      "s3:PutAnalyticsConfiguration",
      "s3:PutBucket*",
      "s3:PutEncryptionConfiguration",
      "s3:PutInventoryConfiguration",
      "s3:PutLifecycleConfiguration",
      "s3:PutMetricsConfiguration",
      "s3:PutReplicationConfiguration",
    ]
    resources = [module.builder_bucket.arn]
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
      module.builder_bucket.arn,
      "${module.builder_bucket.arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalArn"
      values   = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/RoleProwlerScanner"]
    }
  }
}

data "aws_iam_policy_document" "bucket_kms_policy" {
  statement {
    sid    = "AllowAdminAccess"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/RoleTerraformApplier",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/RoleKmsAdministrator",
      ]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowReadOnlyAccess"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/RoleProwlerScanner",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/RolePlatformReadOnly",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/RoleTerraformPlanner",
      ]
    }
    actions = [
      "kms:DescribeKey",
      "kms:GetKeyPolicy",
      "kms:ListKeyPolicies",
      "kms:GetKeyRotationStatus",
      "kms:ListResourceTags",
      "kms:ListGrants"
    ]
    resources = ["*"]
  }
}