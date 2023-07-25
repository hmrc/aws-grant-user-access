# A shared secret between GitHub and AWS that allows AWS
# CodePipeline to authenticate the request came from GitHub.
resource "random_password" "webhook" {
  length  = 100 # must have length less than or equal to 100
  special = false
}

resource "aws_codepipeline_webhook" "default" {
  name            = "${local.pipeline_name}-source-${var.src_repo}"
  authentication  = "GITHUB_HMAC"
  target_action   = "Source"
  target_pipeline = local.pipeline_name

  authentication_configuration {
    secret_token = random_password.webhook.result
  }

  filter {
    json_path    = "$.ref"
    match_equals = "refs/heads/{Branch}"
  }
}

data "github_repository" "this" {
  full_name = "${var.src_org}/${var.src_repo}"
}

# Wire the CodePipeline webhook into a GitHub repository.
resource "github_repository_webhook" "this" {
  repository = data.github_repository.this.name

  configuration {
    url          = aws_codepipeline_webhook.default.url
    content_type = "json"
    insecure_ssl = false
    secret       = random_password.webhook.result
  }

  events = ["push"]
}
