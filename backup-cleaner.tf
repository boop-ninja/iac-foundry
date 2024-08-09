variable "cron_schedule" {
  description = "The cron schedule for the job."
  type        = string
  default     = "0 0 * * *" # Default to daily at midnight
}

variable "older_than_days" {
  description = "Number of days after which files should be removed."
  type        = number
  default     = 30
}

resource "kubernetes_cron_job" "backup_cleanup" {
  metadata {
    name      = "${local.app_name_safe}-backup-cleanup"
    namespace = local.namespace
  }
  spec {
    schedule = var.cron_schedule
    job_template {
      metadata {
        name = "${local.app_name_safe}-backup-cleanup"
        labels = {
          app = local.app_name_safe
        }
      }
      spec {
        template {
          metadata {
            labels = {
              app = local.app_name_safe
            }
          }
          spec {
            container {
              name  = "cleanup-container"
              image = "alpine:latest"

              command = [
                "/bin/sh",
                "-c",
                "apk add --no-cache findutils && find /foundrydata/Backups -type f -mtime +${var.older_than_days} -delete"
              ]

              volume_mount {
                name       = "backups-volume"
                mount_path = "/foundrydata/Backups"
              }
            }

            restart_policy = "OnFailure"

            volume {
              name = "backups-volume"
              persistent_volume_claim {
                claim_name = kubernetes_persistent_volume_claim.backups.metadata[0].name
              }
            }
          }
        }
      }
    }
  }
}
