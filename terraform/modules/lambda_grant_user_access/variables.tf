variable "environment" {
  default     = "example-environment"
  description = "The name of the environment the lambda function is deployed to"
  type        = string
}

variable "environment_variables" {
  default     = { Test : true }
  description = "The environment variables to set on the lambda function."
  type        = map(string)
}

variable "lambda_function_name" {
  description = "The name for this lambda function."
}

variable "tags" {
  default     = {}
  description = "Resource tags"
  type        = map(string)
}

variable "timeout_in_seconds" {
  default     = 900
  description = "How long the lambda is allowed to run in seconds, before timing out."
  type        = number
}

variable "sns_topic_parameter_store_name" {
  default     = null
  description = "Name of parameter store containing SNS Topic ARN"
  type        = string
}

variable "vpc_config" {
  type = object({
    vpc_id              = string
    private_subnet_ids  = list(string)
    private_subnet_arns = list(string)
  })
  default     = null
  description = "VPC config for the lambda function; when null, the function is not attached to a VPC"
}

variable "security_group_ids" {
  type        = list(string)
  default     = []
  description = "Security group IDs to attach to the lambda's ENIs when vpc_config is set"
}
