terraform {
  source = "../../modules//networking"
}

locals {
  common               = read_terragrunt_config(find_in_parent_folders("common/labs.hcl"))
  environment          = local.common.locals.environment
  product              = local.common.locals.product
  region               = local.common.locals.region
  tf_state_bucket_name = local.common.locals.tf_state_bucket_name
}

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "s3" {
    bucket       = "${local.common.locals.tf_state_bucket_name}"
    region       = "${local.common.locals.region}"
    key          = "labs/networking.tfstate"
    encrypt      = true
    kms_key_id   = "alias/s3-${local.common.locals.tf_state_bucket_name}"
    use_lockfile  = true
    acl          = "bucket-owner-full-control"
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
  name                              = "${local.product}-${local.environment}"
  namespace                         = "mdtp"
  slack_notifications_endpoint_name = "com.amazonaws.vpce.eu-west-2.vpce-svc-018ec3a07309aa4d0"
}
