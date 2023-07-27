output "access_log_bucket_id" {
  value = var.environment == "live" ? module.access_log_bucket[0].id : var.log_bucket_name
}
