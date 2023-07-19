terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.src_org
}

locals {
  pipeline_name = var.pipeline
  build_id      = "#{SourceVariables.CommitId}-#{Timestamp.BUILD_TIMESTAMP}"
}
