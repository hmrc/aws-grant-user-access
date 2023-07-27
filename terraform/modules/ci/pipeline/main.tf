locals {
  step_assume_roles    = merge(var.step_assume_roles...)
  access_log_bucket_id = data.aws_ssm_parameter.access_log_bucket_id.value
}

module "common" {
  source               = "../pipeline_common"
  pipeline             = var.pipeline_name
  src_org              = var.src_org
  src_repo             = var.src_repo
  github_token         = data.aws_ssm_parameter.github_api_token.value
  access_log_bucket_id = local.access_log_bucket_id
  admin_role           = var.admin_role
}
