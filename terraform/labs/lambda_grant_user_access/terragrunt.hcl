terraform {
  source = "../../modules//lambda_grant_user_access"
}

locals {
  common  = read_terragrunt_config(find_in_parent_folders("common/labs.hcl"))
  product = local.common.locals.product
  region  = local.common.locals.region
}

include {
  path = find_in_parent_folders("root.hcl")
}

dependency "networking" {
  config_path = "../networking"
}

inputs = {
  region               = local.region
  lambda_function_name = local.product
  timeout_in_seconds   = 900
  environment_variables = {
    "LOG_LEVEL" : "INFO",
    "SLACK_CHANNELS" : "#team-platsec-test-notifications",
    "DRY_RUN" : "true"
  }

  vpc_config         = dependency.networking.outputs.vpc_config
  security_group_ids = [dependency.networking.outputs.grant_user_access_lambda_sg_id]
}
