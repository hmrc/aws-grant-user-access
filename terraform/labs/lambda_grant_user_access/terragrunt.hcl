terraform {
  source = "../../modules//lambda_grant_user_access"
}

locals {
  common  = read_terragrunt_config(find_in_parent_folders("common/labs.hcl"))
  product = local.common.locals.product
}

include {
  path = find_in_parent_folders()
}

inputs = {
  lambda_function_name  = local.product
  environment_variables = { Test : true }
  timeout               = 900
  tags                  = { Git_Project = "https://github.com/hmrc/aws-${local.product}" }
}
