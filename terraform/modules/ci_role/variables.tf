variable "role_name" {
  type = string
}

variable "role_policy_arn" {
  type = string
}

variable "ci_account_id" {
  type = string
}

variable "role_arn_secret_name" {
  type        = string
  description = "the role arn will be stored with this name in AWS Secrets Manager"
}

variable "kms_override_policy_documents" {
  type        = list(string)
  description = "List of IAM policy documents to merge for KMS policy."
  default     = []
}