locals {
  default_policy_arns = concat([aws_iam_policy.build.arn, aws_iam_policy.build_core.arn], var.policy_arns)
  managed_policy_arns = length(var.step_assume_roles) == 0 ? local.default_policy_arns : concat(local.default_policy_arns, [aws_iam_policy.step_assume_roles[0].arn])
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

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

resource "aws_iam_role" "build" {
  name_prefix         = substr(var.step_name, 0, 32)
  description         = "${var.step_name} build"
  assume_role_policy  = data.aws_iam_policy_document.codebuild_assume_role.json
  managed_policy_arns = local.managed_policy_arns

  tags = {
    Step = var.step_name
  }
}

data "aws_iam_policy_document" "build" {
  statement {
    actions = [
      "s3:PutObjectAcl",
      "s3:PutObject"
    ]
    resources = [
      "${var.s3_bucket_arn}/*/build_outp/*"
    ]
  }
}

resource "aws_iam_policy" "build" {
  name_prefix = substr(var.step_name, 0, 32)
  description = "${var.step_name} store artefacts"

  policy = data.aws_iam_policy_document.build.json

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Step = var.step_name
  }
}

data "aws_iam_policy_document" "step_assume_roles" {
  count = length(var.step_assume_roles) == 0 ? 0 : 1
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    resources = values(var.step_assume_roles)
  }
}

resource "aws_iam_policy" "step_assume_roles" {
  count       = length(var.step_assume_roles) == 0 ? 0 : 1
  name_prefix = substr(var.step_name, 0, 32)
  policy      = data.aws_iam_policy_document.step_assume_roles[0].json
  description = "${var.step_name} step assume roles"
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

  # https://docs.aws.amazon.com/codebuild/latest/userguide/auth-and-access-control-iam-identity-based-access-control.html#customer-managed-policies-example-create-vpc-network-interface
  statement {
    actions = [
      "ec2:CreateNetworkInterface",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DeleteNetworkInterface",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeVpcs",
    ]
    resources = ["*"]
  }

  statement {
    actions = [
      "ec2:CreateNetworkInterfacePermission",
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:network-interface/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "ec2:AuthorizedService"
      values = [
        "codebuild.amazonaws.com"
      ]
    }
    condition {
      test     = "ArnEquals"
      variable = "ec2:Subnet"
      values   = var.vpc_config.private_subnet_arns
    }
  }
}

resource "aws_iam_policy" "build_core" {
  name_prefix = substr(var.step_name, 0, 32)
  description = "${var.step_name} build"
  policy      = data.aws_iam_policy_document.build_core.json

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    codebuild_project = var.step_name
  }
}
