terraform {
  required_version = ">= 0.14"
  required_providers {
    aws = {
      version = "~> 3.2"
    }
    rke = {
      source = "rancher/rke"
    }
    rancher2 = {
      source = "rancher/rancher2"
    }
  }
}