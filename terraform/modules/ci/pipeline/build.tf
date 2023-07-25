module "apply_step" {
  for_each = local.step_assume_roles
  source   = "../terraform_step"

  docker_required    = true
  step_name          = "${module.common.pipeline_name}-apply-${each.key}"
  timeout_in_minutes = var.step_timeout_in_minutes

  s3_bucket_arn       = module.common.bucket_arn
  policy_arns         = [module.common.policy_build_core_arn]
  step_assume_roles   = each.value
  build_spec_contents = templatefile("${path.module}/buildspecs/apply.yaml.tpl", { target = each.key })

  vpc_config               = var.vpc_config
  agent_security_group_ids = var.agent_security_group_ids
}

module "build_timestamp_step" {
  source      = "../build_timestamp_step"
  step_name   = "${module.common.pipeline_name}-timestamp"
  policy_arns = [module.common.policy_build_core_arn]
}
