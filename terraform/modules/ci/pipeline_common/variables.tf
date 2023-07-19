variable "pipeline" {
  type = string
}

variable "src_org" {
  type    = string
  default = "hmrc"
}

variable "src_repo" {
  type = string
}

variable "github_token" {
  type = string
}

variable "sns_topic_arn" {
  type    = string
  default = null
}

variable "access_log_bucket_id" {
  description = "The name of the access log bucket"
  type        = string
}

variable "admin_role" {
  description = "The role for bucket policy admin"
  type        = string
}
