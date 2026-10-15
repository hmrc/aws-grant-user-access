locals {
  region               = "eu-west-2"
  environment          = "live"
  account_id           = "638924580364"
  team                 = "platsec"
  product              = "grant-user-access"
  tf_state_bucket_name = "${local.product}-tf-state-${md5(local.environment)}"
}
