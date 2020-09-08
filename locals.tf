locals {
  common_tags = {
    Project = local.project_name
  }
}

locals {
  project_name       = "${var.project_name}-${random_id.rancher.hex}"
  rancher_version    = var.rancher_version
  kubernetes_version = var.kubernetes_version
  email              = var.email
  domain_name        = var.domain_name
  instance_type      = var.instance_type
  nodes              = var.nodes
}
