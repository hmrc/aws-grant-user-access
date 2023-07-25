module "builder" {
  source = "../builder_common/"

  project_name                  = var.project_name
  agent_security_group_ids      = var.agent_security_group_ids
  vpc_config                    = var.vpc_config
  docker_required               = var.docker_required
  project_assume_roles          = var.project_assume_roles
  project_environment_variables = var.project_environment_variables
  timeout_in_minutes            = var.timeout_in_minutes
  src_repo                      = var.src_repo
  src_branch                    = var.src_branch
  buildspec                     = file("${path.module}/buildspecs/plan.yaml")
}