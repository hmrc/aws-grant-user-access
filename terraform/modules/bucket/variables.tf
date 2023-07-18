variable "bucket_name" {
  type        = string
  description = "The name of the S3 bucket to create"
}

variable "versioning_enabled" {
  type        = bool
  description = "When true the s3 bucket contents will be versioned"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Additional tags to apply to the bucket"
  default     = {}
}

variable "force_destroy" {
  type        = bool
  description = "Allow a bucket to be destroyed when it is not empty"
  default     = false
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

variable "write_roles" {
  type        = list(string)
  description = "A list of ARNs to allow actions for writing files"
  default     = []
}

variable "list_roles" {
  type        = list(string)
  description = "A list of ARNs to allow actions for listing file names"
  default     = []
}

variable "metadata_read_roles" {
  type        = list(string)
  description = "A list of ARNs to allow to access metadata to enable bucket audit"
  default     = []
}

variable "data_sensitivity" {
  type        = string
  description = "Defaults to low. For buckets with PII or other sensitive data, the tag data_sensitivity: high must be applied."
  default     = "low"

  validation {
    condition     = var.data_sensitivity == "high" || var.data_sensitivity == "low"
    error_message = "The data_sensitivity value must be \"high\" or \"low\"."
  }
}

variable "restricted_ip_access" {
  type        = list(string)
  description = "A list of IPs to restrict all s3 access to"
  default     = []
}

variable "restricted_vpce_access" {
  type        = list(string)
  description = "A list of VPCe(s) to restrict all s3 access to"
  default     = []
}

variable "data_expiry" {
  type        = string
  description = "1-day, 1-week, 1-month, 90-days, 6-months, 1-year, 7-years, 10-years or forever-config-only"

  validation {
    condition     = var.data_expiry == "1-day" || var.data_expiry == "1-week" || var.data_expiry == "1-month" || var.data_expiry == "90-days" || var.data_expiry == "6-months" || var.data_expiry == "1-year" || var.data_expiry == "7-years" || var.data_expiry == "10-years" || var.data_expiry == "forever-config-only"
    error_message = "The data_expiry value must be \"1-day\", \"1-week\", \"1-month\", \"90-days\", \"6-months\", \"1-year\", \"7-years\", \"10-years\" or \"forever-config-only\"."
  }
}

variable "required_tags_with_restricted_values" {
  type        = map(list(string))
  description = "A map of required tags and their values"
  default     = {}
}

variable "environment" {
  type = string
}

variable "log_bucket_id" {
  type        = string
  description = "The name of the access logs bucket"
}
