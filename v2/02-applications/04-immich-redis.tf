resource "kubernetes_persistent_volume_claim_v1" "immich_redis" {
  metadata {
    name      = "immich-redis-pvc"
    namespace = kubernetes_namespace_v1.immich.metadata[0].name
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

resource "kubernetes_deployment_v1" "immich_redis" {
  metadata {
    name      = "immich-redis"
    namespace = kubernetes_namespace_v1.immich.metadata[0].name
  }


  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "immich-redis"
      }
    }

    template {
      metadata {
        labels = {
          app = "immich-redis"
        }
      }

      spec {
        security_context {
          fs_group               = 999
          fs_group_change_policy = "OnRootMismatch"
          run_as_user            = 999
          run_as_non_root        = true
        }

        container {
          name  = "redis"
          image = "redis:8-alpine"

          args = [
            "redis-server",
            "--dir", "/data",
            "--appendonly", "yes"
          ]

          port {
            container_port = 6379
          }

          volume_mount {
            mount_path = "/data"
            name       = "redis-storage"
          }

          resources {
            requests = {
              memory = "128Mi"
              cpu    = "100m"
            }
            limits = {
              memory = "256Mi"
              cpu    = "500m"
            }
          }
        }

        volume {
          name = "redis-storage"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim_v1.immich_redis.metadata[0].name
          }
        }
      }
    }
  }

  timeouts {
    update = "1m"
    create = "2m"
  }
}

resource "kubernetes_service_v1" "immich_redis" {
  metadata {
    name      = "immich-redis"
    namespace = kubernetes_namespace_v1.immich.metadata[0].name
  }

  spec {
    selector = {
      app = "immich-redis"
    }

    port {
      port        = 6379
      target_port = 6379
    }

    type = "ClusterIP"
  }
}
