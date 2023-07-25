variable "security_group_name" {}

variable "vpc_id" {}

variable "service_name" {}

variable "tags" {
  type = map(string)
}

variable "subnet_ids" {
  type = list(string)
}

variable "endpoint_subdomain_prefix" {
  default = ""
}

variable "subdomains" {
  type = list(string)
}

variable "top_level_domain" {}

variable "create_dns" {
  type        = bool
  description = "Flag for DNS creation - set to false to prevent Route53 private zone creation"
  default     = true
}

variable "create_wildcard" {
  description = "Flag for Wildcard DNS creation - Set to create a wildcard entry in the Route53 zone. Requires create_dns to be true"
  type        = bool
  default     = false
}
