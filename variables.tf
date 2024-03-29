locals {
  app_name_safe = "foundryvtt-${replace(replace(var.domain_name, "/", "-"), ".", "-")}"
  owner         = terraform.workspace
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

variable "deployment_limits" {
  type = object({
    cpu    = string
    memory = string
  })
  default = {
    cpu    = "0.3"
    memory = "1024Mi"
  }
}

variable "additional_env_vars" {
  type        = map(string)
  sensitive   = false
  default     = {}
  description = "description"
}

variable "foundry_modules" {
  type        = object({ dnd_beyond_rolls = bool })
  default     = {
    dnd_beyond_rolls = false
  }
  description = "description"
}


