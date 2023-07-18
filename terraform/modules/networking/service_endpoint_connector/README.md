# How to consume a PrivateLink service

This how-to details the process for consuming a PrivateLink service.

## Summary

A PrivateLink service is a service which is exposed in a VPC in one AWS account and is made available for consumption
in other AWS accounts over a "[PrivateLink](https://docs.aws.amazon.com/AmazonVPC/latest/UserGuide/endpoint-service.html)".

The service is presented in the consumer's VPC as an ENI. The consumer is then free to configure access to the ENI
using the standard mechanisms (Network ACL's, Security Groups, Subnet memberships etc).

Typically a PrivateLink service will sit behind a network load balancer, this is an OSI layer-4 device (transport
layer).

If the PrivateLink service presents over TLS then it is necessary for the consumer to create a Route53 private hosted
zone which maps the FQDN(s) presented in the service's certificate to the ENI. Otherwise the TLS connection cannot be
made securely.

## Example

We have written a `service_endpoint_connector` module which does all the necessary configuration to expose a
PrivateLink service. Its usage is as follows:

### Create a Security Group

Create a security group which will control access to the PrivateLink service.

```terraform
    resource "aws_security_group" "artefacts_private_link_endpoint_security_group" {
      name        = "${var.environment}-externaltest-test-artefacts-private-link-endpoint"
      description = "${var.environment}-externaltest-test-artefacts-private-link-endpoint"
      vpc_id      = "${var.vpc_id}"

      ingress {
        from_port       = "${var.port}"
        to_port         = "${var.port}"
        protocol        = "tcp"
        security_groups = ["${var.permitted_security_groups}"]
      }
    }
```

### Create the connector

Create an instance of the `service_endpoint_connector` module, passing in the above security group.

```terraform
    module "artefacts_private_link_endpoint" {
      source             = "../service_endpoint_connector"
      endpoint_name      = "${var.endpoint_name}"
      service_name       = "${var.artefacts_endpoint_service_name}"
      vpc_id             = "${var.vpc_id}"
      subnet_ids         = "${var.subnet_ids}"
      component          = "${var.component}"
      dns_name           = "${var.artefacts_fqdn}"
      security_group_ids = ["${aws_security_group.artefacts_private_link_endpoint_security_group.id}"]
    }
```

The `service_endpoint_connector` module will create all the necessary configuration, including the required DNS entries,
to consume the PrivateLink service.
