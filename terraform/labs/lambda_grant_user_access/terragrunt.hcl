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
  timeout_in_seconds    = 900
  sns_topic_arn         = "arn:aws:sns:eu-west-2:304923144821:psec-1933-grant-user-access"
  environment_variables = { "LOG_LEVEL" : "INFO" }
  tags                  = { Git_Project = "https://github.com/hmrc/aws-${local.product}" }
}
