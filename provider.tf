provider "aws" {
  region = "us-east-1"
}

provider "rke" {
  log_file = "logs/rke.log"
}

provider "helm" {
  kubernetes {
    config_path = local_file.kube_cluster_yaml.filename
  }
}

provider "rancher2" {
  alias     = "bootstrap"
  api_url   = "https://${local.project_name}.${local.domain_name}"
  bootstrap = true
}

provider "rancher2" {
  api_url   = "https://${local.project_name}.${local.domain_name}"
  token_key = rancher2_bootstrap.admin.token
}
