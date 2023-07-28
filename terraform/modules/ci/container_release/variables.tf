variable "project_name" {
  type = string
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

variable "docker_required" {
  type = bool
}

variable "project_environment_variables" {
  type    = list(map(string))
  default = []
}

variable "project_assume_roles" {
  type        = map(string)
  description = "map of environment variable to role arn for use within the build"
}

variable "timeout_in_minutes" {
  default = 15
}

variable "src_org" {
  type    = string
  default = "hmrc"
}

variable "src_repo" {
  type = string
}

variable "src_branch" {
  type        = string
  default     = "^main"
  description = "Source repository branch"
}

variable "ecr_repository_arn" {
  type        = string
  description = "The ARN that identifies the container image repository"
}
