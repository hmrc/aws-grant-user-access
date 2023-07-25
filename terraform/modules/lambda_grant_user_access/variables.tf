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
