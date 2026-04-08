resource "kubernetes_namespace" "trek" {
  metadata {
    name = "trek"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_deployment" "trek" {
  metadata {
    name      = "trek"
    namespace = kubernetes_namespace.trek.metadata[0].name
  }

  spec {
    replicas = 1

    strategy {
      type = "Recreate"
    }

    selector {
      match_labels = {
        app = "trek"
      }
    }

    template {
      metadata {
        labels = {
          app = "trek"
        }
      }

      spec {
        security_context {
          run_as_non_root = true
        }

        container {
          name  = "trek"
          image = "mauriceboe/trek:latest"

          port {
            container_port = 3000
          }

          security_context {
            read_only_root_filesystem  = true
            allow_privilege_escalation = false
            capabilities {
              drop = ["ALL"]
              add  = ["CHOWN", "SETUID", "SETGID"]
            }
          }

          env {
            name  = "NODE_ENV"
            value = "production"
          }
          env {
            name  = "PORT"
            value = "3000"
          }
          env {
            name = "ENCRYPTION_KEY"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.trek_encryption_key.metadata[0].name
                key  = "ENCRYPTION_KEY"
              }
            }
          }
          env {
            name  = "TZ"
            value = "Europe/London"
          }
          env {
            name  = "LOG_LEVEL"
            value = "info"
          }
          env {
            name  = "ALLOWED_ORIGINS"
            value = "https://trek.shearman.cloud"
          }
          env {
            name  = "FORCE_HTTPS"
            value = "true"
          }
          env {
            name  = "TRUST_PROXY"
            value = "1"
          }
          env {
            name  = "APP_URL"
            value = "https://trek.shearman.cloud"
          }

          volume_mount {
            name       = "data"
            mount_path = "/app/data"
          }
          volume_mount {
            name       = "uploads"
            mount_path = "/app/uploads"
          }
          volume_mount {
            name       = "tmp"
            mount_path = "/tmp"
          }

          liveness_probe {
            http_get {
              path = "/api/health"
              port = 3000
            }
            initial_delay_seconds = 15
            period_seconds        = 30
            timeout_seconds       = 10
            failure_threshold     = 3
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "512Mi"
            }
          }
        }

        volume {
          name = "data"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.trek_data.metadata[0].name
          }
        }
        volume {
          name = "uploads"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.trek_uploads.metadata[0].name
          }
        }
        volume {
          name = "tmp"
          empty_dir {
            medium     = "Memory"
            size_limit = "64Mi"
          }
        }
      }
    }
  }

  depends_on = [
    kubernetes_persistent_volume_claim.trek_data,
    kubernetes_persistent_volume_claim.trek_uploads,
    kubernetes_secret.trek_encryption_key
  ]
}

resource "kubernetes_persistent_volume_claim" "trek_data" {
  metadata {
    name      = "trek-data"
    namespace = kubernetes_namespace.trek.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "10Gi"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "trek_uploads" {
  metadata {
    name      = "trek-uploads"
    namespace = kubernetes_namespace.trek.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]

    resources {
      requests = {
        storage = "20Gi"
      }
    }
  }
}

resource "random_bytes" "encryption_key" {
  length = 32
}

resource "kubernetes_secret" "trek_encryption_key" {
  metadata {
    name      = "trek-encryption-key"
    namespace = kubernetes_namespace.trek.metadata[0].name
  }

  data = {
    ENCRYPTION_KEY = random_bytes.encryption_key.hex
  }

  depends_on = [random_bytes.encryption_key]
}
