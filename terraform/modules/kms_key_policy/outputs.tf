output "policy_document_json" {
  value = data.aws_iam_policy_document.kms.json
}