terraform {
  source = "../../modules//bootstrap"
}

locals {
  common                            = read_terragrunt_config(find_in_parent_folders("common/labs.hcl"))
  account_id                        = get_env("LABS_ACCOUNT_ID", get_aws_account_id())
  environment                       = local.common.locals.environment
  product                           = local.common.locals.product
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
    key            = "${path_relative_to_include()}/bootstrap.tfstate"
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
      "team:product" : "platsec:${local.product}"
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
  environment                       = local.environment
  environment_account_ids           = {}
  log_bucket_name                   = "stackset-access-logs-${local.environment}-${md5(local.environment)}"
  tf_state_bucket_name              = local.tf_state_bucket_name
  tf_state_lock_dynamodb_table_name = local.tf_state_lock_dynamodb_table_name

  tf_read_roles          = ["arn:aws:iam::${local.account_id}:role/RoleTerraformApplier", "arn:aws:iam::${local.account_id}:role/RoleTerraformPlanner", "arn:aws:iam::${local.account_id}:role/RoleSecurityEngineer", "arn:aws:iam::${local.account_id}:role/RoleProwlerScanner"]
  tf_list_roles          = ["arn:aws:iam::${local.account_id}:role/RoleTerraformApplier", "arn:aws:iam::${local.account_id}:role/RoleTerraformPlanner", "arn:aws:iam::${local.account_id}:role/RoleSecurityEngineer", "arn:aws:iam::${local.account_id}:role/RoleProwlerScanner"]
  tf_metadata_read_roles = ["arn:aws:iam::${local.account_id}:role/RoleTerraformApplier", "arn:aws:iam::${local.account_id}:role/RoleTerraformPlanner", "arn:aws:iam::${local.account_id}:role/RoleSecurityEngineer", "arn:aws:iam::${local.account_id}:role/RoleProwlerScanner"]
  tf_write_roles         = ["arn:aws:iam::${local.account_id}:role/RoleTerraformApplier"]
  tf_admin_roles         = ["arn:aws:iam::${local.account_id}:role/RoleTerraformApplier"]
}
