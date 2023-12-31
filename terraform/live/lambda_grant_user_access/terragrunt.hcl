terraform {
  source = "../../modules//lambda_grant_user_access"
}

locals {
  common  = read_terragrunt_config(find_in_parent_folders("common/live.hcl"))
  product = local.common.locals.product
}

include {
  path = find_in_parent_folders()
}

inputs = {
  lambda_function_name           = local.product
  timeout_in_seconds             = 900
  sns_topic_parameter_store_name = "/${local.product}/sns_topic_arn"
  environment_variables          = { "LOG_LEVEL" : "INFO" }
  tags                           = { Git_Project = "https://github.com/hmrc/aws-${local.product}" }
}
