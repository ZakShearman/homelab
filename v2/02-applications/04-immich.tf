resource "kubernetes_namespace_v1" "immich" {
  metadata {
    name = "immich"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  depends_on = [helm_release.longhorn]
}

resource "kubernetes_secret_v1" "immich_pg_user" {
  metadata {
    name      = "immich-pg-user"
    namespace = kubernetes_namespace_v1.immich.metadata[0].name
  }

  type = "opaque"

  data = {
    username = data.sops_file.secrets.data["immich_default_username"]
    password = data.sops_file.secrets.data["immich_default_password"]
  }

  depends_on = [kubernetes_namespace_v1.immich, data.sops_file.secrets]
}

resource "kubectl_manifest" "immich_postgres_cluster" {
  yaml_body = yamlencode({
    "apiVersion" = "postgresql.cnpg.io/v1"
    "kind"       = "Cluster"
    "metadata" = {
      "name"      = "db"
      "namespace" = kubernetes_namespace_v1.immich.metadata[0].name
    }
    "spec" = {
      imageName           = "ghcr.io/tensorchord/cloudnative-vectorchord:18.1-1.1.0"
      instances           = 1
      primaryUpdateMethod = "restart" # We can't use switchover since it's a single instance

      storage = {
        size = "25Gi"
      }

      "postgresql" = {
        "shared_preload_libraries" = ["vchord.so"]
      }

      managed = {
        roles = [
          {
            name      = "immich"
            superuser = true
            login     = true
          }
        ]
      }

      bootstrap = {
        recovery = {
          database = "immich"
          owner    = "immich"
          secret = {
            name = "immich-pg-user"
          }
          volumeSnapshots = {
            storage = {
              name     = "old-db-1"
              kind     = "PersistentVolumeClaim"
              apiGroup = ""
            }
          }
        }
      }
    }
  })

  depends_on = [kubernetes_namespace_v1.immich, helm_release.cnpg, kubernetes_secret_v1.immich_pg_user]
}

resource "kubernetes_persistent_volume_claim_v1" "immich" {
  depends_on = [kubernetes_namespace_v1.immich]

  metadata {
    name      = "immich-pvc"
    namespace = kubernetes_namespace_v1.immich.metadata[0].name
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "150Gi"
      }
    }
  }
}

resource "helm_release" "immich" {
  name       = "immich"
  repository = "oci://ghcr.io/immich-app/immich-charts/"
  chart      = "immich"
  namespace  = kubernetes_namespace_v1.immich.metadata[0].name
  version    = var.immich_chart_version

  values = [
    yamlencode({

      immich = {
        persistence = {
          library = {
            existingClaim = kubernetes_persistent_volume_claim_v1.immich.metadata[0].name
          }
        }
      }

      controllers = {
        main = {
          containers = {
            main = {
              image = {
                tag = var.immich_version
              }

              env = {
                REDIS_HOSTNAME = "immich-redis"
                DB_USERNAME = {
                  valueFrom = {
                    secretKeyRef = {
                      name = "immich-pg-user"
                      key  = "username"
                    }
                  }
                }
                DB_PASSWORD = {
                  valueFrom = {
                    secretKeyRef = {
                      name = "immich-pg-user"
                      key  = "password"
                    }
                  }
                }
                DB_HOSTNAME = "db-rw.${kubernetes_namespace_v1.immich.metadata[0].name}.svc"
              }
            }
          }
        }
      }
    })
  ]

  wait = true
  # If the install fails, automatically roll back
  atomic  = true
  timeout = 120 # 2 minutes

  depends_on = [
    kubernetes_persistent_volume_claim_v1.immich, kubectl_manifest.immich_postgres_cluster,
    kubernetes_deployment_v1.immich_redis, kubernetes_service_v1.immich_redis
  ]
}

resource "kubectl_manifest" "immich_ingressroute" {
  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "immich"
      namespace = kubernetes_namespace_v1.immich.metadata[0].name
      annotations = {
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }

    spec = {
      entryPoints = ["websecure"]
      routes = [
        {
          kind  = "Rule"
          match = "Host(`photos.shearman.cloud`)"
          services = [
            {
              name = "immich-server"
              port = 2283
            }
          ]
        }
      ]
      tls = {
        certResolver = "cloudflare"
      }
    }
  })

  depends_on = [helm_release.traefik]
}
