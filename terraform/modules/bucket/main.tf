module "bucket" {
  source  = "hmrc/s3-bucket-standard/aws"
  version = "1.7.0"

  bucket_name   = var.bucket_name
  force_destroy = var.force_destroy

  list_roles             = var.list_roles
  read_roles             = var.read_roles
  write_roles            = var.write_roles
  metadata_read_roles    = var.metadata_read_roles
  admin_roles            = var.admin_roles
  data_expiry            = var.data_expiry
  data_sensitivity       = var.data_sensitivity
  restricted_ip_access   = var.restricted_ip_access
  restricted_vpce_access = var.restricted_vpce_access

  required_tags_with_restricted_values = var.required_tags_with_restricted_values

  log_bucket_id = var.log_bucket_name
  tags = {
    allow_delete = false
  }
}
