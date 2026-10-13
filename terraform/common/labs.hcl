locals {
  region               = "eu-west-2"
  environment          = "labs"
  account_id           = "132732819912"
  team                 = "platsec"
  product              = "grant-user-access"
  tf_state_bucket_name = "aws-${local.product}-tf-state-${md5(local.environment)}"
}
