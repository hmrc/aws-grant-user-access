module "access_log_bucket" {
  count       = var.environment == "live" ? 1 : 0
  source      = "../access_log_bucket"
  bucket_name = var.log_bucket_name
  admin_roles = var.tf_admin_roles
  read_roles  = var.tf_read_roles
}

module "terraform_state" {
  source           = "../bucket"
  bucket_name      = var.tf_state_bucket_name
  data_expiry      = "forever-config-only"
  data_sensitivity = "high"

  read_roles          = var.tf_read_roles
  list_roles          = var.tf_list_roles
  write_roles         = var.tf_write_roles
  metadata_read_roles = var.tf_metadata_read_roles
  admin_roles         = var.tf_admin_roles

  environment     = var.environment
  log_bucket_name = var.log_bucket_name
}
