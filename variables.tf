locals {
  app_name_safe = "foundryvtt-${replace(replace(var.domain_name, "/", "-"), ".", "-")}"
  owner         = terraform.workspace
  limits = {
    cpu    = try(var.limits.cpu, "0.2")
    memory = try(var.limits.memory, "1024Mi")
  }
}


variable "app_name" {
  type        = string
  default     = ""
  description = "description"
}

variable "domain_name" {
  type = string
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

variable "limits" {
  type    = object({})
  default = {}
}

variable "additional_env_vars" {
  type        = object({})
  sensitive   = false
  default     = {}
  description = "description"
}


output "domain" {
  value = "https://${var.domain_name}"
}
