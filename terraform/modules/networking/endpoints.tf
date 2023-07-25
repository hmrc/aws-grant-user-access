data "aws_region" "current" {}

module "artifactory_endpoint_connector" {
  source = "./service_endpoint_connector"

  security_group_name = "${local.vpc_name}-artifactory-endpoint"
  vpc_id              = module.vpc.vpc_id
  service_name        = local.live_artifactory_endpoint_name
  subnet_ids          = module.vpc.private_subnets

  subdomains = [
    "artefacts",
    "dockerhub",
    "pythonpips",
  ]
  top_level_domain = "tax.service.gov.uk"
  tags = {
    Purpose : "${local.vpc_name}-artifactory-endpoint-connector"
  }
}

# CloudWatch Logs to be able to see agent logs in CodeBuild
resource "aws_vpc_endpoint" "cloudwatch_logs" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.aws_interface_endpoints.id,
  ]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true

  tags = {
    Name : "${local.vpc_name}-logs"
  }
}

# ECR for ECR Native API
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.aws_interface_endpoints.id,
  ]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true

  tags = {
    Name : "${local.vpc_name}-ecr-api"
  }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.secretsmanager"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.aws_interface_endpoints.id,
  ]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true

  tags = {
    Name : "${local.vpc_name}-secretsmanager"
  }
}


# ECR for Docker Registry API
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.aws_interface_endpoints.id,
  ]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true

  tags = {
    Name : "${local.vpc_name}-ecr-dkr"
  }
}

resource "aws_vpc_endpoint" "lambda" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.lambda"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.aws_interface_endpoints.id,
  ]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true

  tags = {
    Name : "${local.vpc_name}-lambda"
  }
}

resource "aws_vpc_endpoint" "ecs" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ecs"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.aws_interface_endpoints.id,
  ]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true

  tags = {
    Name : "${local.vpc_name}-ecs"
  }
}

# S3 for downloading source code
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  tags = {
    Name : "${local.vpc_name}-s3"
  }
}

resource "aws_vpc_endpoint" "sts" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.sts"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.aws_interface_endpoints.id,
  ]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true

  tags = {
    Name : "${local.vpc_name}-sts"
  }
}

resource "aws_vpc_endpoint" "execute_api" {
  vpc_id            = module.vpc.vpc_id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.execute-api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.aws_interface_endpoints.id,
  ]
  subnet_ids          = module.vpc.private_subnets
  private_dns_enabled = true

  tags = {
    Name : "${local.vpc_name}-execute-api"
  }
}
