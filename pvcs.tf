
resource "kubernetes_persistent_volume_claim" "backups" {
  depends_on = [kubernetes_namespace.i]
  metadata {
    name      = "${local.app_name_safe}-backups"
    namespace = local.namespace
    labels    = local.common_labels
  }
  spec {
    storage_class_name = var.storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.pvc_storage_sizes["backups"]
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "config" {
  depends_on = [kubernetes_namespace.i]
  metadata {
    name      = "${local.app_name_safe}-config"
    namespace = local.namespace
    labels    = local.common_labels
  }
  spec {
    storage_class_name = var.storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.pvc_storage_sizes["config"]
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "data" {
  depends_on = [kubernetes_namespace.i]
  metadata {
    name      = "${local.app_name_safe}-data"
    namespace = local.namespace
    labels    = local.common_labels
  }
  spec {
    storage_class_name = var.storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.pvc_storage_sizes["data"]
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "core" {
  depends_on = [kubernetes_namespace.i]
  metadata {
    name      = "${local.app_name_safe}-core"
    namespace = local.namespace
    labels    = local.common_labels
  }
  spec {
    storage_class_name = var.storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.pvc_storage_sizes["core"]
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "moradin" {
  count      = var.foundry_modules.dnd_beyond_rolls ? 1 : 0
  depends_on = [kubernetes_namespace.i]
  metadata {
    name      = "${local.app_name_safe}-moradin"
    namespace = local.namespace
    labels    = local.common_labels
  }
  spec {
    storage_class_name = var.storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.pvc_storage_sizes["moradin"]
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "syncthing" {
  count      = var.foundry_modules.syncthing ? 1 : 0
  depends_on = [kubernetes_namespace.i]
  metadata {
    name      = "${local.app_name_safe}-syncthing"
    namespace = local.namespace
    labels    = local.common_labels
  }
  spec {
    storage_class_name = var.storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.pvc_storage_sizes["syncthing"]
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "app" {
  depends_on = [kubernetes_namespace.i]
  metadata {
    name      = "${local.app_name_safe}-app"
    namespace = local.namespace
    labels    = local.common_labels
  }
  spec {
    storage_class_name = var.storage_class_name
    access_modes       = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = var.pvc_storage_sizes["app"]
      }
    }
  }
}

