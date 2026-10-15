locals {
  common               = read_terragrunt_config(find_in_parent_folders("common/live.hcl"))
  environment          = local.common.locals.environment
  team                 = local.common.locals.team
  region               = local.common.locals.region
  tf_state_bucket_name = local.common.locals.tf_state_bucket_name
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "${local.tf_state_bucket_name}"
    region         = "${local.region}"
    key            = "live/${path_relative_to_include()}.tfstate"
    encrypt        = true
    kms_key_id     = "alias/s3-${local.tf_state_bucket_name}"
    use_lockfile    = true
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
  region = "${local.region}"
  default_tags {
    tags = {
      Team        = "${local.team}"
      Region      = "${local.region}"
      Service     = "aws-grant-user-access"
      Environment = "${local.environment}"
      Source      = "https://github.com/hmrc/aws-grant-user-access/"
    }
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
  EOF
}


inputs = {
  environment = local.environment
}
