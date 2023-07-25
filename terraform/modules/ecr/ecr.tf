resource "aws_ecr_repository" "ecr" {
  name = var.ecr_repository_name
  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_repository_policy" "ecr_policy" {
  repository = aws_ecr_repository.ecr.id
  policy     = data.aws_iam_policy_document.ecr_pull_policy.json
}
