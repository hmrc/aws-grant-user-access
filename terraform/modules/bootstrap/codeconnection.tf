resource "aws_codestarconnections_connection" "this" {
  count = var.environment == "live" ? 1 : 0

  name          = var.environment
  provider_type = "GitHub"
}
