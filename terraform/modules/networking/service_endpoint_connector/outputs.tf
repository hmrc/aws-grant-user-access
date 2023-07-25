output "security_group_id" {
  value = aws_security_group.endpoint_sg.id
}

output "service_endpoint_id" {
  value = aws_vpc_endpoint.service_endpoint.id
}

output "service_endpoint_ip" {
  value = data.aws_network_interface.service_endpoint_eni_0.private_ip
}

output "service_endpoint_zone_ids" {
  value = aws_route53_zone.service_zone.*.zone_id
}
