variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket to create"
}

variable "admin_roles" {
  type        = list(string)
  description = "A list of roles to allow admin access to bucket"
  default     = []
}

variable "read_roles" {
  type        = list(string)
  description = "A list of ARNs to allow actions for reading files"
  default     = []
}

