data "aws_iam_policy_document" "ecr" {
  statement {
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    actions = [
      "ecr:CompleteLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:InitiateLayerUpload",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage"
    ]
    resources = [var.ecr_repository_arn]
  }
}

resource "aws_iam_policy" "ecr" {
  name_prefix = substr(var.project_name, 0, 60)
  description = "${var.project_name} upload container image to ECR"
  policy      = data.aws_iam_policy_document.ecr.json

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Step = var.project_name
  }
}
