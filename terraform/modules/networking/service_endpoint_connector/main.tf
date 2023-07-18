locals {
  subdomains     = formatlist("%s%s", var.endpoint_subdomain_prefix, sort(compact(var.subdomains)))
  zone_count     = var.create_dns ? length(local.subdomains) : 0
  wildcard_count = var.create_wildcard == true ? local.zone_count : 0
}

resource "aws_vpc_endpoint" "service_endpoint" {
  vpc_id             = var.vpc_id
  vpc_endpoint_type  = "Interface"
  service_name       = var.service_name
  subnet_ids         = var.subnet_ids
  security_group_ids = [aws_security_group.endpoint_sg.id]
  tags               = var.tags
}

resource "aws_route53_zone" "service_zone" {
  count = local.zone_count
  name  = "${element(local.subdomains, count.index)}.${var.top_level_domain}"

  vpc {
    vpc_id = var.vpc_id
  }

  lifecycle {
    ignore_changes = [
      vpc,
    ]
  }

  tags = var.tags
}

resource "aws_route53_record" "service_dns_name" {
  count   = local.zone_count
  zone_id = element(aws_route53_zone.service_zone.*.id, count.index)
  name    = ""
  type    = "A"

  alias {
    name                   = lookup(aws_vpc_endpoint.service_endpoint.dns_entry[0], "dns_name")
    zone_id                = lookup(aws_vpc_endpoint.service_endpoint.dns_entry[0], "hosted_zone_id")
    evaluate_target_health = true
  }

  depends_on = [
    aws_route53_zone.service_zone,
    aws_vpc_endpoint.service_endpoint,
  ]
}

resource "aws_route53_record" "wildcard_dns_name" {
  count   = local.wildcard_count
  zone_id = element(aws_route53_zone.service_zone.*.id, count.index)
  name    = "*"
  type    = "A"

  alias {
    name                   = lookup(aws_vpc_endpoint.service_endpoint.dns_entry[0], "dns_name")
    zone_id                = lookup(aws_vpc_endpoint.service_endpoint.dns_entry[0], "hosted_zone_id")
    evaluate_target_health = true
  }

  depends_on = [
    aws_route53_zone.service_zone,
    aws_vpc_endpoint.service_endpoint,
  ]
}

resource "aws_security_group" "endpoint_sg" {
  name        = var.security_group_name
  description = var.security_group_name
  vpc_id      = var.vpc_id

  tags = merge(var.tags, {
    Name = var.security_group_name
  })
}

data "aws_network_interface" "service_endpoint_eni_0" {
  id = element(tolist(aws_vpc_endpoint.service_endpoint.network_interface_ids), 0)
}
