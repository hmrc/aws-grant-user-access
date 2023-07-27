variable "pipeline_name" {
  type = string
}

variable "src_org" {
  type    = string
  default = "hmrc"
}

variable "src_repo" {
  type = string
}

variable "branch" {
  type    = string
  default = "main"
}

variable "step_timeout_in_minutes" {
  default = 15
}

variable "step_assume_roles" {
  type = list(map(map(string)))
}

variable "admin_role" {
  type        = string
  description = "IAM role to allow admin access to bucket"
}

variable "agent_security_group_ids" {
  type = list(string)
}

variable "vpc_config" {
  type = object({
    private_subnet_ids  = list(string),
    private_subnet_arns = list(string),
    vpc_id              = string,
  })
}
