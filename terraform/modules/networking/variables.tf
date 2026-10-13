variable "name" {
  type    = string
  default = "stackset-live"
}

variable "namespace" {
  type    = string
  default = "mdtp"
}

variable "slack_notifications_endpoint_name" {
  description = "Slack notifications VPC endpoint service name for this environment."
  type        = string
  nullable    = false
}
