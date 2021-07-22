variable "kube_host" {
}

variable "kube_crt" {
  default = ""
}
variable "kube_key" {
  default = ""
}
variable "app_name" {
  type        = string
  default     = ""
  description = "description"
}
locals {
  app_name_safe = "foundryvtt-${replace(replace(local.domain_name, "/", "-"), ".", "-")}"
  domain_name = terraform.workspace
}

variable "image" {
  type        = string
  default     = ""
  description = "description"
}

output "domain" {
  value = "https://${local.domain_name}"
}

