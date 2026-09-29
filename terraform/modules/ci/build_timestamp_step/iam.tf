
data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    principals {
      identifiers = ["codebuild.amazonaws.com"]
      type        = "Service"
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "codebuild" {
  name_prefix        = substr(var.step_name, 0, 32)
  description        = "${var.step_name} upload"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json

  tags = {
    Step = var.step_name
  }
}

resource "aws_iam_role_policy_attachments_exclusive" "codebuild" {
  role_name   = aws_iam_role.codebuild.name
  policy_arns = var.policy_arns
}
