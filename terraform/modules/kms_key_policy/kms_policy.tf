locals {
  readers = var.read_roles != null ? var.read_roles : formatlist(
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/%s",
    ["RoleTerraformPlanner", "PlatformReadOnly", "RoleProwlerScanner"]
  )
  writers = var.write_roles != null ? var.write_roles : formatlist(
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/%s",
    ["RoleTerraformApplier"]
  )
  admins = var.admin_roles != null ? var.admin_roles : formatlist(
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/%s",
    ["RoleKmsAdministrator", "RoleTerraformApplier"]
  )
  all_roles = distinct(concat(local.admins, local.writers, local.readers))
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "kms" {

  statement {
    sid    = "DenyAccessToDecrypt"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "kms:Decrypt",
    ]

    resources = ["*"]

    condition {
      test     = "StringNotLike"
      variable = "aws:PrincipalArn"
      // writers need to be able to decrypt as part of a MultiPartUpload
      values = distinct(concat(local.readers, local.writers))
    }
  }

  statement {
    sid    = "DenyAccessToNonWriteUsers"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
    ]

    resources = ["*"]

    condition {
      test     = "StringNotLike"
      variable = "aws:PrincipalArn"
      values   = local.writers
    }
  }

  statement {
    sid    = "DenyAccessToNonKMSAdmin"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "kms:Create*",
      "kms:Enable*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
    ]

    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalArn"
      values   = local.admins
    }
  }

  statement {
    sid    = "DenyGetAccessToNonKMSAdmin"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "kms:GetParametersForImport",
      "kms:GetPublicKey",
    ]

    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalArn"
      values   = local.admins
    }
  }

  statement {
    sid    = "DenyAccessToNonKMSAdminAndDescribeRoles"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "kms:Describe*",
      "kms:GetKeyPolicy",
      "kms:GetKeyRotationStatus",
      "kms:List*",
    ]

    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalArn"
      values   = local.all_roles
    }
  }

  statement {
    sid    = "DenyUnknownKMSActions"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    not_actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion",
      "kms:Encrypt",
      "kms:GenerateDataKey*",
      "kms:ReEncrypt*",
      "kms:Decrypt",
    ]

    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalArn"
      values   = local.admins
    }
  }

  /*
    kms actions are explicitly denied to everyone that
    should not have them
  */
  statement {
    sid    = "AllowAccessForUsers" # Overrides default statement in shared_secret module
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = [
      "kms:*",
    ]

    resources = ["*"]

    condition {
      test     = "StringLike"
      variable = "aws:PrincipalArn"
      values   = local.all_roles
    }
  }
}
