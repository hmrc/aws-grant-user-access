module "ecr" {
  source = "../ecr"

  ecr_repository_name  = var.lambda_function_name
  lambda_function_name = var.lambda_function_name
}

module "lambda" {
  source = "../lambda"

  ecr_repository_url    = module.ecr.ecr_repository_url
  environment           = var.environment
  environment_variables = var.environment_variables
  lambda_function_name  = var.lambda_function_name
  ecr_image_tag         = aws_ssm_parameter.grant_user_access.value
  timeout_in_seconds    = var.timeout_in_seconds
  tags                  = var.tags
}
