locals {
  namespace = kubernetes_namespace.i.metadata[0].name
  common_labels = {
    app = local.app_name_safe
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
    name = local.app_name_safe
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

resource "kubernetes_deployment" "i" {
  depends_on = [kubernetes_namespace.i]
  metadata {
    name = local.app_name_safe
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
        volume {
          name = local.volumes.foundry_data.name
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.o.metadata[0].name
          }
        }
        container {
          image = "mbround18/foundryvtt-docker:latest"
          name  = local.app_name_safe

          resources {
            limits = {
              cpu    = "0.2"
              memory = "512Mi"
            }
          }

          env {
            name  = "HOSTNAME"
            value = local.domain_name
          }

          env {
            name  = "SSL_PROXY"
            value = "false"
          }

          port {
            name           = local.ports.web.name
            container_port = local.ports.web.port
          }

          volume_mount {
            mount_path = local.volumes.foundry_data.path
            name       = local.volumes.foundry_data.name
          }
        }

        container {
          name = "${local.app_name_safe}-syncthing"
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
            name = local.ports.syncthing.name
            container_port = local.ports.syncthing.port
          }

          port {
            name = "sync"
            container_port = 22000
          }

          volume_mount {
            name = local.volumes.foundry_data.name
            sub_path = "syncthing-config"
            mount_path = "/var/syncthing/config"
          }

          volume_mount {
            name = local.volumes.foundry_data.name
            mount_path = "/var/syncthing${local.volumes.foundry_data.path}"
          }

        }

      }
    }
  }
}