
variable "environment" {
  type        = string
  description = "Environment name"
}

variable "environment_account_ids" {
  type        = map(string)
  description = "Map of AWS Account ID per environment"
}

variable "tf_read_roles" {
  type        = list(string)
  description = "A list of roles to allow read access to bucket objects"
  default     = []
}

variable "tf_write_roles" {
  type        = list(string)
  description = "A list of roles to allow write access to bucket objects"
  default     = []
}

variable "tf_admin_roles" {
  type        = list(string)
  description = "A list of roles to allow admin access to bucket"
  default     = []
}

variable "tf_list_roles" {
  type        = list(string)
  description = "A list of ARNs to allow actions for listing file names"
  default     = []
}

variable "tf_metadata_read_roles" {
  type        = list(string)
  description = "A list of ARNs to allow to access metadata to enable bucket audit"
  default     = []
}

variable "tf_state_bucket_name" {
  type        = string
  description = "The name of the Terraform state bucket"
}

variable "tf_state_lock_dynamodb_table_name" {
  type        = string
  description = "The name of the Terraform state lock Dynamodb table"
}

variable "log_bucket_name" {
  type        = string
  description = "The name of the access logs bucket"
}
