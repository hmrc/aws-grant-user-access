terraform {
  source = "../../modules//lambda_grant_user_access"
}

locals {
  common  = read_terragrunt_config(find_in_parent_folders("common/live.hcl"))
  product = local.common.locals.product
}

include {
  path = find_in_parent_folders("root.hcl")
}

dependency "networking" {
  config_path = "../networking"
}

inputs = {
  lambda_function_name  = local.product
  timeout_in_seconds    = 900
  environment_variables = { "LOG_LEVEL" : "INFO", "SLACK_CHANNELS" : "#aws-prod-alerts" }
  tags                  = { Git_Project = "https://github.com/hmrc/aws-${local.product}" }

  vpc_config         = dependency.networking.outputs.vpc_config
  security_group_ids = [dependency.networking.outputs.grant_user_access_lambda_sg_id]
}
