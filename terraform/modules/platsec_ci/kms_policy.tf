locals {
  readers = concat(
    formatlist(
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/%s",
      ["RoleTerraformPlanner", "PlatformReadOnly", "RoleProwlerScanner"]
    ),
    ["arn:aws:iam::${var.ci_account_id}:role/RoleTerraformPlanner"]
  )
  writers = concat(
    formatlist(
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/%s",
      ["RoleTerraformApplier"]
    ),
    ["arn:aws:iam::${var.ci_account_id}:role/RoleTerraformApplier"]
  )
  admins = formatlist(
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/%s",
    ["RoleKmsAdministrator", "RoleTerraformApplier"]
  )
}

data "aws_caller_identity" "current" {}

module "kms_key_policy_document" {
  source = "../kms_key_policy"

  read_roles  = local.readers
  write_roles = local.writers
  admin_roles = local.admins
}
