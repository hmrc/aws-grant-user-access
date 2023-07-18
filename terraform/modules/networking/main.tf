locals {
  vpc_name                       = module.label.id
  live_artifactory_endpoint_name = "com.amazonaws.vpce.eu-west-2.vpce-svc-06f82f7a1b56d9744"
}

module "label" {
  source = "github.com/hmrc/terraform-null-label?ref=0.25.0"

  namespace = var.namespace
  name      = var.name
}
