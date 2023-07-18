module "ecr" {
  source = "../ecr"

  ecr_repository_name = var.lambda_function_name
}

module "lambda" {
  source = "../lambda"

  ecr_image_tag = var.ecr_image_tag
  ecr_repository_url = module.ecr.outputs.ecr_repository_url
  environment = var.environment
  environment_variables = var.environment_variables
  lambda_function_name = var.lambda_function_name
}
