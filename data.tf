data "aws_subnet_ids" "available" {
  vpc_id = var.vpc_id
}

data "aws_route53_zone" "dns_zone" {
  name = local.domain_name
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu-minimal/images/*/ubuntu-focal-20.04-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

data "template_file" "cloud_config" {
  template = file("${path.module}/files/cloud-config.yaml")
}

data "rancher2_user" "admin" {
  username   = "admin"
  depends_on = [rancher2_bootstrap.admin]
}
