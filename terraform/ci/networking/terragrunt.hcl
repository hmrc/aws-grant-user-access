terraform {
  source = "../../modules//networking"
}

locals {
  common      = read_terragrunt_config(find_in_parent_folders("common/live.hcl"))
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
    key            = "ci/${path_relative_to_include()}.tfstate"
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
# https://github.com/terraform-aws-modules/terraform-aws-vpc/issues/625
provider "aws" {
  alias  = "no-default-tags"
  region = "eu-west-2"
}

terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 4.67.0"
      configuration_aliases = [aws.no-default-tags]
    }
  }
}
  EOF
}

inputs = {
  name      = "${local.product}-${local.environment}"
  namespace = "mdtp"
}
