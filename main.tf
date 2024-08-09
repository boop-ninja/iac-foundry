locals {
  namespace     = kubernetes_namespace.i.metadata[0].name
  common_labels = { app = local.app_name_safe, hosting = "foundry-vtt" }
  ports         = { web = { name = "web", port = 4444 }, syncthing = { name = "syncthing", port = 8384 } }

  volume_mounts = [
    {
      name       = "app"
      mount_path = "/foundryvtt"
      sub_path   = ""
    },
    {
      name       = "core"
      mount_path = "/foundrydata/"
      sub_path   = ""
    },
    {
      name       = "backups"
      mount_path = "/foundrydata/Backups"
      sub_path   = ""
    },
    {
      name       = "config"
      mount_path = "/foundrydata/Config"
      sub_path   = ""
    },
    {
      name       = "data"
      mount_path = "/foundrydata/Data"
      sub_path   = ""
    }
  ]
}

resource "kubernetes_namespace" "i" {
  metadata {
    name   = local.app_name_safe
    labels = local.common_labels
  }
}

resource "kubernetes_config_map" "i" {
  metadata {
    name      = "${local.app_name_safe}-additional-env"
    namespace = kubernetes_namespace.i.metadata[0].name
  }

  data = merge(var.additional_env_vars, {
    HOSTNAME  = var.domain_name
    SSL_PROXY = "false"
  })
}

resource "kubernetes_deployment" "i" {
  depends_on = [kubernetes_namespace.i]
  metadata {
    name      = local.app_name_safe
    namespace = local.namespace
    labels    = local.common_labels
  }
  spec {
    replicas = 1
    selector {
      match_labels = local.common_labels
    }
    template {
      metadata {
        namespace = local.namespace
        labels    = local.common_labels
      }
      spec {
        init_container {
          name  = "${local.app_name_safe}-init"
          image = "busybox:latest"

          command = [
            "sh",
            "-c",
            "chown -R 1000:1000 /var/syncthing"
          ]

          volume_mount {
            name       = "syncthing"
            mount_path = "/var/syncthing/config"
            sub_path   = "syncthing-config"
          }

          volume_mount {
            name       = "data"
            mount_path = "/var/syncthing/foundrydata"
          }
        }

        container {
          image = var.image
          name  = local.app_name_safe

          resources {
            limits = {
              cpu    = var.deployment_limits["cpu"]
              memory = var.deployment_limits["memory"]
            }
          }

          env_from {
            config_map_ref {
              name = kubernetes_config_map.i.metadata[0].name
            }
          }

          port {
            name           = local.ports.web.name
            container_port = local.ports.web.port
          }

          dynamic "volume_mount" {
            for_each = local.volume_mounts
            content {
              name       = volume_mount.value.name
              mount_path = volume_mount.value.mount_path
              sub_path   = volume_mount.value.sub_path != "" ? volume_mount.value.sub_path : null
            }
          }
        }

        dynamic "container" {
          for_each = var.foundry_modules.syncthing ? [1] : []
          content {
            name  = "${local.app_name_safe}-syncthing"
            image = "syncthing/syncthing:latest"

            env {
              name  = "PUID"
              value = "1000"
            }
            env {
              name  = "PGID"
              value = "1000"
            }
            env {
              name  = "TZ"
              value = "America/Los_Angeles"
            }

            port {
              name           = local.ports.syncthing.name
              container_port = local.ports.syncthing.port
            }

            port {
              name           = "sync"
              container_port = 22000
            }

            volume_mount {
              name       = "syncthing"
              sub_path   = "syncthing"
              mount_path = "/var/syncthing/config"
            }

            volume_mount {
              name       = "data"
              mount_path = "/var/syncthing/foundrydata"
            }
          }
        }

        dynamic "volume" {
          for_each = local.volume_mounts
          content {
            name = volume.value.name
            persistent_volume_claim {
              claim_name = "kubernetes_persistent_volume_claim.${volume.value.name}.metadata[0].name"
            }
          }
        }

        dynamic "volume" {
          for_each = var.foundry_modules.syncthing ? [1] : []
          content {
            name = "syncthing"
            persistent_volume_claim {
              claim_name = kubernetes_persistent_volume_claim.syncthing.0.metadata[0].name
            }
          }
        }

        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secrets
          content {
            name = image_pull_secrets.value
          }
        }
      }
    }
  }
}


resource "helm_release" "dnd_beyond_rolls" {
  depends_on = [kubernetes_namespace.i]
  count      = var.foundry_modules.dnd_beyond_rolls ? 1 : 0
  chart      = "fvtt-dndbeyond-companion"
  repository = "https://mbround18.github.io/helm-charts/"
  name       = "${local.app_name_safe}-dndbeyond-rolls"
  namespace  = local.namespace

  set {
    name  = "ingress.enabled"
    value = "true"
  }

  set {
    name  = "ingress.hosts[0].host"
    value = var.domain_name
  }

  set {
    name  = "ingress.hosts[0].paths[0].path"
    value = "/dndbeyond-rolls"
  }

  set {
    name  = "ingress.tls[0].secretName"
    value = "${local.app_name_safe}-dnd-beyond-rolls-tls"
  }

  set {
    name  = "ingress.tls[0].hosts[0]"
    value = var.domain_name
  }
}


