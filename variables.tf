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
  description = "Configuration for Foundry modules"
  type = object({
    syncthing        = bool
    dnd_beyond_rolls = bool
  })
  default = {
    syncthing        = false
    dnd_beyond_rolls = false
  }
}

variable "pvc_storage_sizes" {
  description = "Storage sizes for PVCs"
  type        = map(string)
  default = {
    backups   = "10Gi"
    config    = "1Gi"
    data      = "20Gi"
    core      = "2Gi"
    moradin   = "1Gi"
    syncthing = "500Mi"
    app       = "4Gi"
  }
}

variable "storage_class_name" {
  description = "The storage class to be used for PVCs"
  type        = string
  default     = "longhorn"
}

