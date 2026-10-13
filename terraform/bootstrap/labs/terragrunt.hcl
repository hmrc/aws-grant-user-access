terraform {
  source = "../../modules//bootstrap"
}

locals {
  common               = read_terragrunt_config(find_in_parent_folders("common/labs.hcl"))
  account_id           = local.common.locals.account_id
  environment          = local.common.locals.environment
  team                 = local.common.locals.team
  region               = local.common.locals.region
  tf_state_bucket_name = local.common.locals.tf_state_bucket_name
}

# the key in this block needs fixing to "bootstrap.tfstate"
# the object in s3 needs to be moved first from "./bootstrap.tfstate"
# to "bootstrap.tfstate" in short move the file and delete the
# path_relative_to_include
generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket         = "${local.tf_state_bucket_name}"
    region         = "eu-west-2"
    key            = "bootstrap.tfstate"
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
  region = "eu-west-2"
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
  environment          = local.environment
  log_bucket_name      = "platsec-development-access-logs"
  tf_state_bucket_name = local.tf_state_bucket_name

  tf_read_roles          = ["arn:aws:iam::${local.account_id}:role/RoleTerraformApplier", "arn:aws:iam::${local.account_id}:role/RoleTerraformPlanner", "arn:aws:iam::${local.account_id}:role/RoleSecurityEngineer", "arn:aws:iam::${local.account_id}:role/RoleProwlerScanner"]
  tf_list_roles          = ["arn:aws:iam::${local.account_id}:role/RoleTerraformApplier", "arn:aws:iam::${local.account_id}:role/RoleTerraformPlanner", "arn:aws:iam::${local.account_id}:role/RoleSecurityEngineer", "arn:aws:iam::${local.account_id}:role/RoleProwlerScanner"]
  tf_metadata_read_roles = ["arn:aws:iam::${local.account_id}:role/RoleTerraformApplier", "arn:aws:iam::${local.account_id}:role/RoleTerraformPlanner", "arn:aws:iam::${local.account_id}:role/RoleSecurityEngineer", "arn:aws:iam::${local.account_id}:role/RoleProwlerScanner"]
  tf_write_roles         = ["arn:aws:iam::${local.account_id}:role/RoleTerraformApplier", "arn:aws:iam::${local.account_id}:role/RoleTerraformPlanner"]
  tf_admin_roles         = ["arn:aws:iam::${local.account_id}:role/RoleTerraformApplier"]
}
