locals {
  namespace = kubernetes_namespace.i.metadata[0].name
  common_labels = {
    app     = local.app_name_safe
    hosting = "foundry-vtt"
  }
  ports = {
    web = {
      name = "web"
      port = 4444
    }
    syncthing = {
      name = "syncthing"
      port = 8384
    }
  }
  volumes = {
    foundry_data = {
      name = "foundry-data"
      path = "/foundrydata"
      size = "10Gi"
    }
    foundry_app = {
      name = "foundry-app"
      path = "/foundryvtt"
      size = "2Gi"
    }
  }
}

resource "kubernetes_namespace" "i" {
  metadata {
    name   = local.app_name_safe
    labels = local.common_labels
  }
}

resource "kubernetes_persistent_volume_claim" "o" {
  depends_on = [kubernetes_namespace.i]
  metadata {
    name      = local.app_name_safe
    namespace = local.namespace
    labels    = local.common_labels
  }
  spec {
    storage_class_name = "longhorn"
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = local.volumes.foundry_data.size
      }
      limits = {
        storage = local.volumes.foundry_data.size
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "i" {
  depends_on = [kubernetes_namespace.i]
  metadata {
    name      = "${local.app_name_safe}-app"
    namespace = local.namespace
    labels    = local.common_labels
  }
  spec {
    storage_class_name = "longhorn"
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = local.volumes.foundry_app.size
      }
      limits = {
        storage = local.volumes.foundry_app.size
      }
    }
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
            name       = local.volumes.foundry_data.name
            sub_path   = "syncthing-config"
            mount_path = "/var/syncthing/config"
          }

          volume_mount {
            name       = local.volumes.foundry_data.name
            mount_path = "/var/syncthing${local.volumes.foundry_data.path}"
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

          volume_mount {
            mount_path = local.volumes.foundry_data.path
            name       = local.volumes.foundry_data.name
          }

          volume_mount {
            mount_path = local.volumes.foundry_app.path
            name       = local.volumes.foundry_app.name
          }
        }

        volume {
          name = local.volumes.foundry_data.name
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.o.metadata[0].name
          }
        }
        volume {
          name = local.volumes.foundry_app.name
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.i.metadata[0].name
          }
        }

        dynamic "image_pull_secrets" {
          for_each = var.image_pull_secrets
          content {
            name = image_pull_secrets.value
          }
        }

        container {


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
            name       = local.volumes.foundry_data.name
            sub_path   = "syncthing-config"
            mount_path = "/var/syncthing/config"
          }

          volume_mount {
            name       = local.volumes.foundry_data.name
            mount_path = "/var/syncthing${local.volumes.foundry_data.path}"
          }

        }

      }
    }
  }
}

resource "helm_release" "dnd_beyond_rolls" {
  depends_on = [kubernetes_namespace.i]
  for_each = var.foundry_modules.dnd_beyond_rolls ? [1] : []
  chart = "fvtt-dndbeyond-companion"
  repository = "https://mbround18.github.io/helm-charts/"
  name  = "${local.app_name_safe}-dndbeyond-rolls"
  namespace = local.namespace

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


