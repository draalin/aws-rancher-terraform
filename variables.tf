variable "vpc_id" {
  type        = string
  description = "vpc id"
}

variable "domain_name" {
  type        = string
  description = "domain name"
}

variable "email" {
  type        = string
  description = "email"
}

variable "password" {
  type        = string
  description = "rancher password"
}

variable "project_name" {
  type        = string
  description = "project name"
  default     = "rancher"
}

variable "nodes" {
  type        = string
  description = "nodes"
  default     = "3"
}

variable "instance_type" {
  type        = string
  description = "instance type"
  default     = "t2.large"
}

variable "rancher_version" {
  type        = string
  description = "rancher version"
  default     = "v2.4.8"
}

variable "kubernetes_version" {
  type        = string
  description = "kubernetes version"
  default     = "v1.16.13-rancher1-2"
}
