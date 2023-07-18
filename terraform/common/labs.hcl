locals {
  account_id  = "979783897929"
  environment = "labs"
  product = "grant-user-access"
  tf_state_bucket_name  = "${local.product}-tf-state-${md5(local.environment)}"
  tf_state_lock_dynamodb_table_name  = "${local.product}-tf-lock-${md5(local.environment)}"
}
