locals {
  account_id  = "638924580364"  # auth account
  environment = "live"
  product     = "grant-user-access"

  tf_state_bucket_name              = "${local.product}-tf-state-${md5(local.environment)}"
  tf_state_lock_dynamodb_table_name = "${local.product}-tf-lock-${md5(local.environment)}"
}
