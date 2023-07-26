terraform {
  source = "../../modules/ci//pipeline"
}

locals {
  common  = read_terragrunt_config(find_in_parent_folders("common/labs.hcl"))
  product = local.common.locals.product
  labs_admin_roles = {
    "TERRAFORM_PROVISIONER_ROLE_ARN" = "arn:aws:iam::${get_aws_account_id()}:role/RoleTerraformProvisioner"
  }
}

include {
  path = find_in_parent_folders()
}

dependency "networking" {
  config_path = "../networking"
}

inputs = {
  pipeline_name = "${local.product}-pipeline"
  src_repo      = "aws-${local.product}"
  branch        = "main"

  step_assume_roles = [
    { ci = local.labs_admin_roles },
    { labs = local.labs_admin_roles },
  ]

  vpc_config = dependency.networking.outputs.vpc_config
  agent_security_group_ids = [
    dependency.networking.outputs.ci_agent_to_endpoints_sg_id,
    dependency.networking.outputs.ci_agent_to_internet_sg_id
  ]

  step_timeout_in_minutes = 30
}
