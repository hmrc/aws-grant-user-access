variable "ecr_image_tag" {
  default     = "latest"
  description = "The ECR image tag"
  type        = string
}

variable "ecr_repository_url" {
  description = "The ECR repository URL"
  type        = string
}

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

variable "image_command" {
  default     = ["main.handle"]
  description = "The image command to run for the lambda handler function."
  type        = list(string)
}

variable "lambda_function_name" {
  default     = "grant-user-access"
  description = "The name for this lambda function."
}

variable "lambda_git_project" {
  default     = "https://github.com/hmrc/aws-grant-user-access"
  description = "The URL for the GitHub project"
  type        = string
}

variable "memory_size" {
  default     = 128
  description = "The amount of memory to allocate to the lambda function."
  type        = number
}

variable "reserved_concurrent_executions" {
  description = "The number of reserved concurrent executions for this lambda function."
  type        = number
  default     = -1
}

variable "timeout" {
  default     = 900
  description = "How long the lambda is allowed to run in seconds, before timing out."
  type        = number
}
