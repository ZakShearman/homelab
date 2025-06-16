locals {
  immich_pvc_name = "immich-pvc"
}

resource "kubernetes_namespace" "immich" {
  metadata {
    name = var.immich_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  depends_on = [helm_release.longhorn]
}

resource "kubernetes_secret" "immich_pg_user" {
  metadata {
    name = "immich-pg-user"
    namespace = var.immich_namespace
  }

  type = "opaque"

  data = {
    username = data.sops_file.secrets.data["immich_default_username"]
    password = data.sops_file.secrets.data["immich_default_password"]
  }

  depends_on = [var.immich_namespace, data.sops_file.secrets]
}

resource "kubectl_manifest" "immich_pgql_cluster" {
  yaml_body = yamlencode({
    "apiVersion" = "postgresql.cnpg.io/v1"
    "kind"       = "Cluster"
    "metadata" = {
      "name"      = "db"
      "namespace" = var.immich_namespace
    }
    "spec" = {
      imageName = "ghcr.io/tensorchord/cloudnative-vectorchord:16-0.3.0"
      instances = 1
      primaryUpdateMethod = "restart" # We can't use switchover since it's a single instance

      storage = {
        size = "10Gi"
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
        initdb = {
          database = "immich"
          owner    = "immich"
          secret = {
            name = "immich-pg-user"
          }
          postInitSQL = [
            "CREATE EXTENSION IF NOT EXISTS vchord CASCADE;",
            "CREATE EXTENSION IF NOT EXISTS cube CASCADE;",
            "CREATE EXTENSION IF NOT EXISTS earthdistance CASCADE;",
          ]
        }
      }
    }
  })

  depends_on = [var.immich_namespace, helm_release.cnpg, kubernetes_secret.immich_pg_user]
}

resource "kubernetes_persistent_volume_claim" "immich" {
  depends_on = [kubernetes_namespace.immich]

  metadata {
    name      = local.immich_pvc_name
    namespace = var.immich_namespace
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "100Gi"
      }
    }
  }
}

resource "helm_release" "immich" {
  name       = "immich"
  repository = "oci://ghcr.io/immich-app/immich-charts/"
  chart      = "immich"
  namespace  = var.immich_namespace
  version    = var.immich_chart_version

  values = [
    yamlencode({
      image = {
        tag = var.immich_version
      }

      immich = {
        persistence = {
          library = {
            existingClaim = local.immich_pvc_name
          }
        }
      }

      redis = {
        enabled = true
      }

      env = {
        DB_USERNAME = {
          valueFrom = {
            secretKeyRef = {
              name = "immich-pg-user"
              key = "username"
            }
          }
        }
        DB_PASSWORD = {
          valueFrom = {
            secretKeyRef = {
              name = "immich-pg-user"
              key = "password"
            }
          }
        }
        DB_HOSTNAME = "db-rw.${var.immich_namespace}.svc"
      }
    })
  ]

  wait = true
  # If the install fails, automatically roll back
  atomic = true
  timeout = 120 # 2 minutes

  depends_on = [kubernetes_persistent_volume_claim.immich, kubectl_manifest.immich_pgql_cluster]
}

resource "kubectl_manifest" "immich_ingressroute" {
  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "immich"
      namespace = kubernetes_namespace.immich.metadata[0].name
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