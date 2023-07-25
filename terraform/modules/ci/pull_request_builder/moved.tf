moved {
  from = aws_codebuild_project.build
  to   = module.builder.aws_codebuild_project.build
}

moved {
  from = aws_codebuild_project.build
  to   = module.builder.aws_codebuild_project.build
}

moved {
  from = aws_codebuild_webhook.build
  to   = module.builder.aws_codebuild_webhook.build
}

moved {
  from = aws_iam_policy.build
  to   = module.builder.aws_iam_policy.build
}

moved {
  from = aws_iam_policy.build_core
  to   = module.builder.aws_iam_policy.build_core
}

moved {
  from = aws_iam_policy.project_assume_roles[0]
  to   = module.builder.aws_iam_policy.project_assume_roles[0]
}

moved {
  from = aws_iam_role.build
  to   = module.builder.aws_iam_role.build
}

moved {
  from = aws_s3_bucket_policy.bucket
  to   = module.builder.aws_s3_bucket_policy.bucket
}

moved {
  from = module.pr_builder_bucket.aws_kms_alias.bucket_kms_alias
  to   = module.builder.module.builder_bucket.aws_kms_alias.bucket_kms_alias
}

moved {
  from = module.pr_builder_bucket.aws_kms_key.bucket_kms_key
  to   = module.builder.module.builder_bucket.aws_kms_key.bucket_kms_key
}

moved {
  from = module.pr_builder_bucket.aws_s3_bucket.bucket
  to   = module.builder.module.builder_bucket.aws_s3_bucket.bucket
}

moved {
  from = module.pr_builder_bucket.aws_s3_bucket_ownership_controls.bucket_owner_enforced
  to   = module.builder.module.builder_bucket.aws_s3_bucket_ownership_controls.bucket_owner_enforced
}

moved {
  from = module.pr_builder_bucket.aws_s3_bucket_public_access_block.public_blocked
  to   = module.builder.module.builder_bucket.aws_s3_bucket_public_access_block.public_blocked
}
