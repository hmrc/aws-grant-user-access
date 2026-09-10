resource "aws_security_group" "grant_user_access_lambda" {
  name_prefix = "${local.vpc_name}-grant-user-access-lambda-"
  vpc_id      = module.vpc.vpc_id
}

resource "aws_security_group_rule" "grant_user_access_lambda_https_egress" {
  security_group_id = aws_security_group.grant_user_access_lambda.id
  type              = "egress"
  description       = "HTTPS to AWS APIs through NAT"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "grant_user_access_lambda_to_slack" {
  security_group_id        = aws_security_group.grant_user_access_lambda.id
  type                     = "egress"
  description              = "HTTPS to Slack notifications endpoint"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.slack_notifications_endpoint_connector.security_group_id
}

resource "aws_security_group_rule" "slack_from_grant_user_access_lambda" {
  security_group_id        = module.slack_notifications_endpoint_connector.security_group_id
  type                     = "ingress"
  description              = "HTTPS from grant-user-access Lambda"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.grant_user_access_lambda.id
}
