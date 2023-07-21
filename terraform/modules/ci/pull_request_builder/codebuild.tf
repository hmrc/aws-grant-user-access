locals {
  github_event_patterns = ["PULL_REQUEST_CREATED", "PULL_REQUEST_UPDATED", "PULL_REQUEST_REOPENED"]
}

resource "aws_codebuild_project" "build" {
  name          = var.project_name
  description   = "For ${var.project_name}"
  build_timeout = var.timeout_in_minutes

  service_role = aws_iam_role.build.arn

  vpc_config {
    security_group_ids = var.agent_security_group_ids
    subnets            = var.vpc_config.private_subnet_ids
    vpc_id             = var.vpc_config.vpc_id
  }

  cache {
    type  = "LOCAL"
    modes = var.docker_required ? ["LOCAL_DOCKER_LAYER_CACHE", "LOCAL_SOURCE_CACHE"] : ["LOCAL_SOURCE_CACHE"]
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:6.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = var.docker_required

    dynamic "environment_variable" {
      for_each = var.project_assume_roles
      content {
        type  = "PLAINTEXT"
        name  = environment_variable.key
        value = environment_variable.value
      }
    }

    dynamic "environment_variable" {
      for_each = var.project_environment_variables
      content {
        type  = environment_variable.value.type
        name  = environment_variable.value.name
        value = environment_variable.value.value
      }
    }

  }

  logs_config {
    cloudwatch_logs {
      group_name  = var.project_name
      stream_name = var.project_name
    }
  }

  artifacts {
    type = "NO_ARTIFACTS"
  }
  source {
    type                = "GITHUB"
    location            = "https://github.com/${var.src_org}/${var.src_repo}.git"
    git_clone_depth     = 1
    report_build_status = true
    buildspec           = file("${path.module}/buildspecs/plan.yaml")
  }

  # source_version = "^main" ## takes a regex? ...so as to exclude main branch?
}

resource "aws_codebuild_webhook" "build" {
  project_name = aws_codebuild_project.build.name
  build_type   = "BUILD"

  filter_group {
    filter {
      type    = "EVENT"
      pattern = join(",", local.github_event_patterns)
    }
  }
}
