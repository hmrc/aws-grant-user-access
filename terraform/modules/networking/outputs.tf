output "vpc_config" {
  value = {
    vpc_id              = module.vpc.vpc_id,
    private_subnet_ids  = module.vpc.private_subnets,
    private_subnet_arns = module.vpc.private_subnet_arns,
  }
}

output "ci_agent_to_endpoints_sg_id" {
  value = aws_security_group.ci_agent_to_endpoints.id
}

output "ci_agent_to_internet_sg_id" {
  value = aws_security_group.ci_agent_to_internet.id
}
