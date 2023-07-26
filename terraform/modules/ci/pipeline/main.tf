locals {
  step_assume_roles    = merge(var.step_assume_roles...)
  tf_admin_role        = local.step_assume_roles["labs"]["TERRAFORM_PROVISIONER_ROLE_ARN"]
  access_log_bucket_id = data.aws_ssm_parameter.access_log_bucket_id.value
}

module "common" {
  source               = "../pipeline_common"
  pipeline             = var.pipeline_name
  src_org              = var.src_org
  src_repo             = var.src_repo
  github_token         = data.aws_ssm_parameter.github_api_token.value
  access_log_bucket_id = local.access_log_bucket_id
  admin_role           = local.tf_admin_role
}
