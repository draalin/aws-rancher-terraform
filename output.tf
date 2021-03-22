output "rancher_ips" {
  value = aws_instance.rancher-master.*.public_ip
}

output "rancher_url" {
  value = rancher2_bootstrap.admin.url
}

output "rancher_token" {
  value = rancher2_bootstrap.admin.token
}

output "rancher_password" {
  value = var.password
}