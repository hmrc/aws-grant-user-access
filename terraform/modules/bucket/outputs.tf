output "id" {
  description = "The name of the bucket"
  value       = module.bucket.id
}

output "arn" {
  description = "The ARN of the bucket"
  value       = module.bucket.arn
}

output "bucket_regional_domain_name" {
  value = module.bucket.bucket_regional_domain_name
}

output "kms_alias_arn" {
  description = "The ARN of the created KMS key alias"
  value       = module.bucket.kms_alias_arn
}

output "kms_key_arn" {
  description = "The ARN of the created KMS key"
  value       = module.bucket.kms_key_arn
}

output "kms_key_id" {
  description = "The ID of the created KMS key"
  value       = module.bucket.kms_key_id
}

