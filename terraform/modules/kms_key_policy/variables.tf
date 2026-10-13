variable "read_roles" {
  type        = list(string)
  description = "List of IAM Role ARNs allowed ReadOnly/Decrypt permissions"
  default     = null
}

variable "write_roles" {
  type        = list(string)
  description = "List of IAM Role ARNs allowed Encrypt/Decrypt permissions"
  default     = null
}

variable "admin_roles" {
  type        = list(string)
  description = "List of IAM Role ARNs allowed KMS admin permissions"
  default     = null
}