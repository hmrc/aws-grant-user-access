locals {
  terraform_roles = ["RoleTerraformApplier", "RoleTerraformPlanner"]
}

data "aws_iam_role" "terraform" {
  for_each = toset(local.terraform_roles)
  name     = each.key
}

module "share_role_arn" {
  for_each                  = toset(local.terraform_roles)
  source                    = "git::https://github.com/hmrc/public-artefact-store.git//modules/share_secret?ref=867799d8c5b4191636c9fc6b09a42e06acdd7746"
  secret_name               = "/shared/ci-terraform-${lower(trimprefix(each.key, "RoleTerraform"))}-role-arn"
  secret_value              = data.aws_iam_role.terraform[each.key].arn
  allowed_account_ids       = [var.ci_account_id]
  override_policy_documents = [module.kms_key_policy_document.policy_document_json]
  tags                      = {}
}
