terraform {
  source = "../../modules/ci//container_release"
}

locals {
  common          = read_terragrunt_config(find_in_parent_folders("common/live.hcl"))
  product         = local.common.locals.product
  live_account_id = local.common.locals.account_id

  labs_common     = read_terragrunt_config(find_in_parent_folders("common/labs.hcl"))
  labs_account_id = local.labs_common.locals.account_id
}

include {
  path = find_in_parent_folders()
}

dependency "networking" {
  config_path = "../networking"
}

inputs = {
  docker_required = true
  project_name    = "${local.product}-container-release-builder"
  project_assume_roles = {
    "TERRAFORM_APPLIER_ROLE_ARN" = "arn:aws:iam::${local.live_account_id}:role/RoleTerraformApplier"
    "TERRAFORM_PLANNER_ROLE_ARN" = "arn:aws:iam::${local.live_account_id}:role/RoleTerraformPlanner"
  }

  src_repo   = "aws-${local.product}"
  src_branch = "main"

  vpc_config = dependency.networking.outputs.vpc_config
  agent_security_group_ids = [
    dependency.networking.outputs.ci_agent_to_endpoints_sg_id,
    dependency.networking.outputs.ci_agent_to_internet_sg_id
  ]
  timeout_in_minutes = 30
  ecr_repository_arn = "arn:aws:ecr:eu-west-2:${local.live_account_id}:repository/${local.product}"
}
