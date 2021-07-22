resource "kubernetes_service" "i" {
  metadata {
    name   = local.app_name_safe
    namespace = local.namespace
    labels = local.common_labels
  }
  spec {
    selector         = local.common_labels
    session_affinity = "ClientIP"

    port {
      name        = local.ports.web.name
      port        = 80
      target_port = local.ports.web.port
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_service" "s" {
  metadata {
    name   = "${local.app_name_safe}-syncthing"
    namespace = local.namespace
    labels = local.common_labels
  }
  spec {
    selector         = local.common_labels
    session_affinity = "ClientIP"

    port {
      name        = local.ports.syncthing.name
      port        = 80
      target_port = local.ports.syncthing.port
    }

    type = "ClusterIP"
  }
}

resource "kubernetes_ingress" "s" {
  depends_on = [kubernetes_namespace.i, kubernetes_service.s]

  metadata {
    name      = "${local.app_name_safe}-syncthing"
    namespace = local.app_name_safe
    labels    = local.common_labels
    annotations = {
      "traefik.ingress.kubernetes.io/rule-type" = "PathPrefixStrip"
//      "traefik.ingress.kubernetes.io/request-modifier" = "AddPrefix: /sync"
    }
  }

  spec {
    rule {
      host = replace(local.domain_name, "/^([[:alnum:]-]+).([[:alnum:]-]+.[[:alnum:]-]+)$/", "$1-admin.$2")
      http {
        path {
          backend {
            service_name = kubernetes_service.s.metadata[0].name
            service_port = 80
          }
          path = "/"
        }
      }
    }
    tls {
      secret_name = kubernetes_secret.tls.metadata[0].name
    }
  }
}

resource "kubernetes_ingress" "i" {
  depends_on = [kubernetes_namespace.i, kubernetes_service.i]

  metadata {
    name      = local.app_name_safe
    namespace = local.app_name_safe
    labels    = local.common_labels
  }

  spec {
    rule {
      host = local.domain_name
      http {
        path {
          backend {
            service_name = local.app_name_safe
            service_port = 80
          }
          path = "/"
        }
      }
    }
    tls {
      secret_name = kubernetes_secret.tls.metadata[0].name
    }
  }
}
