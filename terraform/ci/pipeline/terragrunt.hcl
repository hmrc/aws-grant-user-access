terraform {
  source = "../../modules/ci//pipeline"
}

locals {
  common  = read_terragrunt_config(find_in_parent_folders("common/live.hcl"))
  product = local.common.locals.product

  labs_common     = read_terragrunt_config(find_in_parent_folders("common/labs.hcl"))
  labs_account_id = local.labs_common.locals.account_id
  labs_admin_roles = {
    "TERRAFORM_PROVISIONER_ROLE_ARN" = "arn:aws:iam::${local.labs_account_id}:role/RoleTerraformApplier"
  }

  live_account_id = local.common.locals.account_id
  live_admin_roles = {
    "TERRAFORM_APPLIER_ROLE_ARN" = "arn:aws:iam::${local.live_account_id}:role/RoleTerraformApplier"
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
    { labs = local.labs_admin_roles },
    { live = local.live_admin_roles },
    { ci = local.live_admin_roles },
  ]
  admin_role = local.live_admin_roles["TERRAFORM_APPLIER_ROLE_ARN"]

  vpc_config = dependency.networking.outputs.vpc_config
  agent_security_group_ids = [
    dependency.networking.outputs.ci_agent_to_endpoints_sg_id,
    dependency.networking.outputs.ci_agent_to_internet_sg_id
  ]

  step_timeout_in_minutes = 30
}
