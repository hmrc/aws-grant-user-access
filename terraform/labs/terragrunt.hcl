locals {
  common      = read_terragrunt_config(find_in_parent_folders("common/labs.hcl"))
  account_id  = local.common.locals.account_id
  environment = local.common.locals.environment
  product     = local.common.locals.product

  tf_state_bucket_name              = local.common.locals.tf_state_bucket_name
  tf_state_lock_dynamodb_table_name = local.common.locals.tf_state_lock_dynamodb_table_name
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "${local.tf_state_bucket_name}"
    region         = "eu-west-2"
    key            = "labs/${path_relative_to_include()}.tfstate"
    encrypt        = true
    kms_key_id     = "alias/s3-${local.tf_state_bucket_name}"
    dynamodb_table = "${local.tf_state_lock_dynamodb_table_name}"
    acl            = "bucket-owner-full-control"
  }
}
EOF
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      "team:product" : "infra:${local.product}"
      "Git_Project"  : "aws-${local.product}"
      "Environment"  : "${local.environment}"
    }
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.8.0"
    }
  }
}
  EOF
}


inputs = {
  environment = local.environment
}
