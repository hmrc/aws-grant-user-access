terraform {
  source = "../../modules//bootstrap"
}

locals {
  common      = read_terragrunt_config("../../common/labs.hcl")
  account_id = local.common.locals.account_id
  environment = local.common.locals.environment
  product     = local.common.locals.product
  tf_state_bucket_name  = local.common.locals.tf_state_bucket_name
  tf_state_lock_dynamodb_table_name  = local.common.locals.tf_state_lock_dynamodb_table_name
}

generate "local" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "local" {
    path = "${path_relative_to_include()}/bootstrap.tfstate"
  }
}
EOF
}

# generate "backend" {
#   path      = "backend.tf"
#   if_exists = "overwrite_terragrunt"
#   contents  = <<EOF
# terraform {
#   backend "s3" {
#     bucket         = "${local.tf_state_bucket_name}"
#     region         = "eu-west-2"
#     key            = "${path_relative_to_include()}/bootstrap.tfstate"
#     encrypt        = true
#     kms_key_id     = "alias/s3-${local.tf_state_bucket_name}"
#     dynamodb_table = "${local.tf_state_lock_dynamodb_table_name}"
#     acl            = "bucket-owner-full-control"
#   }
# }
# EOF
# }

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
  environment                       = local.environment
  log_bucket_id                     = "stackset-access-logs-${local.environment}-${md5(local.environment)}"
  tf_state_bucket_name              = local.tf_state_bucket_name
  tf_state_lock_dynamodb_table_name = local.tf_state_lock_dynamodb_table_name

  tf_read_roles           = ["arn:aws:iam::${local.account_id}:role/RoleTerraformProvisioner", "arn:aws:iam::${local.account_id}:role/RoleSecurityReadOnly"]
  tf_list_roles           = ["arn:aws:iam::${local.account_id}:role/RoleTerraformProvisioner", "arn:aws:iam::${local.account_id}:role/RoleSecurityReadOnly"]
  tf_metadata_read_roles  = ["arn:aws:iam::${local.account_id}:role/RoleTerraformProvisioner", "arn:aws:iam::${local.account_id}:role/RoleSecurityReadOnly"]
  tf_write_roles          = ["arn:aws:iam::${local.account_id}:role/RoleTerraformProvisioner"]
  tf_admin_roles          = ["arn:aws:iam::${local.account_id}:role/RoleTerraformProvisioner"]
}
