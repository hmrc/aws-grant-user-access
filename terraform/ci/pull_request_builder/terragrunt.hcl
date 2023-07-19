terraform {
  source = "../../modules/ci//pull_request_builder"
}

locals {
  common  = read_terragrunt_config(find_in_parent_folders("common/labs.hcl"))
  product = local.common.locals.product
}

include {
  path = find_in_parent_folders()
}

dependency "networking" {
  config_path = "../networking"
}

inputs = {
  docker_required = true
  project_name    = "${local.product}-pr-builder"
  project_assume_roles = {
    "LABS_TERRAFORM_PROVISIONER_ROLE_ARN" = "arn:aws:iam::${get_aws_account_id()}:role/RoleTerraformProvisioner"
  }

  src_repo = "aws-${local.product}"

  vpc_config = dependency.networking.outputs.vpc_config
  agent_security_group_ids = [
    dependency.networking.outputs.ci_agent_to_endpoints_sg_id,
    dependency.networking.outputs.ci_agent_to_internet_sg_id
  ]
  timeout_in_minutes = 30
}
