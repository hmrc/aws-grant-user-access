resource "aws_security_group" "aws_interface_endpoints" {
  name   = "${local.vpc_name}-aws-interface-endpoints"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ci_agent_to_internet" {
  name_prefix = "${local.vpc_name}-agent-to-internet"
  vpc_id      = module.vpc.vpc_id
  egress {
    description = "HTTP to Internet"
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "HTTPS to Internet"
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ci_agent_to_endpoints" {
  name_prefix = "${local.vpc_name}-agent-to-endpoints"
  vpc_id      = module.vpc.vpc_id

  egress {
    description     = "HTTPS to MDTP Artifactory"
    from_port       = 443
    protocol        = "tcp"
    to_port         = 443
    security_groups = [module.artifactory_endpoint_connector.security_group_id]
  }

  egress {
    description     = "HTTPS to AWS Gateway Endpoints"
    from_port       = 443
    protocol        = "tcp"
    to_port         = 443
    prefix_list_ids = [aws_vpc_endpoint.s3.prefix_list_id]
  }

  egress {
    description     = "HTTPS to AWS Interface Endpoints"
    from_port       = 443
    protocol        = "tcp"
    to_port         = 443
    security_groups = [aws_security_group.aws_interface_endpoints.id]
  }
}

resource "aws_security_group_rule" "ci_agents_to_artifactory" {
  security_group_id        = module.artifactory_endpoint_connector.security_group_id
  description              = "HTTPS from CI to Artifactory Endpoint"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.ci_agent_to_endpoints.id
}
