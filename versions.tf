terraform {
  required_version = ">= 0.13"
  required_providers {
    rke = {
      source = "rancher/rke"
    }
    rancher2 = {
      source = "terraform-providers/rancher2"
    }
  }
}