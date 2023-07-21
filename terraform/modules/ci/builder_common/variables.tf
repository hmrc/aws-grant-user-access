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
  default     = null
  description = "Source repository branch"
}

variable "buildspec" {
  type        = string
  description = "The build specification to use for this build project's related builds"
}

variable "project_iam_policy_arns" {
  type        = list(string)
  default     = []
  description = "ARNs of additional iam policies to be attached to Codebuild service role"
}

variable "github_webhook_events" {
  type        = list(string)
  default     = ["PULL_REQUEST_MERGED"]
  description = "List of Github Webhook events"
}

