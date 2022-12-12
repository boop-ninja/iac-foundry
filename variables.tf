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

variable "domain_name" {
  type = string
}

locals {
  app_name_safe = "foundryvtt-${replace(replace(var.domain_name, "/", "-"), ".", "-")}"
  owner         = terraform.workspace
  additional_env_vars = flatten([
    for key, value in var.additional_env_vars : {
      name  = key
      value = value
    }
  ])
}

variable "image" {
  type        = string
  default     = "mbround18/foundryvtt-docker:latest"
  description = "description"
}

variable "image_pull_secrets" {
  default     = []
  description = "Secret Names for image puller secrets"
}

variable "additional_env_vars" {
  type      = map(string)
  sensitive = true
  default = {}
  description = "description"
}


output "domain" {
  value = "https://${var.domain_name}"
}
