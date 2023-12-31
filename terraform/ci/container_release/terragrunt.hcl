terraform {
  source = "../../modules/ci//container_release"
}

locals {
  common          = read_terragrunt_config(find_in_parent_folders("common/live.hcl"))
  product         = local.common.locals.product
  live_account_id = get_env("LIVE_ACCOUNT_ID")

  labs_common     = read_terragrunt_config(find_in_parent_folders("common/labs.hcl"))
  labs_account_id = get_env("LABS_ACCOUNT_ID")
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
    "LABS_TERRAFORM_APPLIER_ROLE_ARN" = "arn:aws:iam::${local.labs_account_id}:role/RoleTerraformApplier"
    "LABS_TERRAFORM_PLANNER_ROLE_ARN" = "arn:aws:iam::${local.labs_account_id}:role/RoleTerraformPlanner"
    "LIVE_TERRAFORM_APPLIER_ROLE_ARN" = "arn:aws:iam::${local.live_account_id}:role/RoleTerraformApplier"
    "LIVE_TERRAFORM_PLANNER_ROLE_ARN" = "arn:aws:iam::${local.live_account_id}:role/RoleTerraformPlanner"
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
