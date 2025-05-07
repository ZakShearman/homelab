# I hate the install of this application. It is fragile, it boots slowly, depends on waiting for things to *hopefully* be ready, etc..
resource "kubernetes_namespace" "firefly" {
  metadata {
    name = var.firefly_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_secret" "firefly_pg_user" {
  metadata {
    name      = "firefly-pg-user"
    namespace = kubernetes_namespace.firefly.metadata[0].name
  }

  type = "Opaque"

  data = {
    username = data.sops_file.secrets.data["firefly_db_username"]
    password = data.sops_file.secrets.data["firefly_db_password"]
  }

  depends_on = [var.firefly_namespace, data.sops_file.secrets]
}

resource "kubectl_manifest" "firefly_pgql_cluster" {
  yaml_body = yamlencode({
    "apiVersion" = "postgresql.cnpg.io/v1"
    "kind"       = "Cluster"
    "metadata" = {
      "name"      = "db"
      "namespace" = kubernetes_namespace.firefly.metadata[0].name
    }
    "spec" = {
      instances = 1

      storage = {
        size = "10Gi"
      }

      managed = {
        roles = [
          {
            name      = "firefly"
            superuser = true
            login     = true
          }
        ]
      }

      bootstrap = {
        initdb = {
          database = "firefly"
          owner    = "firefly"
          secret = {
            name = kubernetes_secret.firefly_pg_user.metadata[0].name
          }
        }
      }
    }
  })

  depends_on = [var.firefly_namespace, helm_release.cnpg, kubernetes_secret.firefly_pg_user]
}

resource "helm_release" "firefly_iii" {
  name       = "firefly-iii"
  repository = "https://firefly-iii.github.io/kubernetes/"
  chart      = "firefly-iii-stack"
  namespace  = var.firefly_namespace
  version = var.firefly_chart_version

  # We create it manually above
  create_namespace = false

  values = [
    yamlencode(
      {
        firefly-db = {
          enabled = false
        }

        firefly-iii = {
          config = {
            env = {
              DB_CONNECTION = "pgsql"
              DB_HOST     = "db-rw.${kubernetes_namespace.firefly.metadata[0].name}.svc"
              DB_PORT     = "5432"
              DB_DATABASE = "firefly"
              TZ          = "Europe/London"
            }

            envValueFrom = {
              DB_USERNAME = {
                secretKeyRef = {
                  name = kubernetes_secret.firefly_pg_user.metadata[0].name
                  key  = "username"
                }
              }
              DB_PASSWORD = {
                secretKeyRef = {
                  name = kubernetes_secret.firefly_pg_user.metadata[0].name
                  key  = "password"
                }
              }
            }
          }

          cronjob = {
            enabled = true

            auth = {
              token = data.sops_file.secrets.data["firefly_cli_token"]
            }

            schedule = "0 */2 * * *" # Every 2 hours
          }
        }
      }
    )
  ]

  wait = true
  # Firefly fails horrendously and doesn't properly uninstall leaving a shit show. Just don't be atomic I guess....
  atomic = false
  timeout = 120 # 2 minutes

  depends_on = [
    helm_release.longhorn, kubernetes_namespace.firefly, kubectl_manifest.firefly_pgql_cluster
  ]
}
