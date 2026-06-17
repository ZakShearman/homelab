locals {
  traefik_cf_secret_name = "cloudflare-api-key"
}

resource "kubernetes_namespace_v1" "traefik" {
  metadata {
    name = "traefik"
    labels = {
      "app.kubernetes.io/managed-by"       = "terraform"
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "kubernetes_secret_v1" "traefik_cf_api_key" {
  metadata {
    name      = local.traefik_cf_secret_name
    namespace = kubernetes_namespace_v1.traefik.metadata[0].name
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = {
    CLOUDFLARE_EMAIL         = data.sops_file.secrets.data["cloudflare_email"]
    CLOUDFLARE_DNS_API_TOKEN = data.sops_file.secrets.data["cloudflare_dns_api_token"]
  }

  depends_on = [kubernetes_namespace_v1.traefik, data.sops_file.secrets]
}

resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  namespace  = kubernetes_namespace_v1.traefik.metadata[0].name
  version    = var.traefik_version

  # We create it manually above
  create_namespace = false
  wait             = false
  # Traefik helm chart doesn't test install correctly and always fails.
  # atomic = true
  timeout = 60 # 1 minute

  values = [
    yamlencode({
      ports = {
        web = {
          port = 80

          http = {
            redirections = {
              entryPoint = {
                to        = "websecure"
                scheme    = "https"
                permanent = true
              }
            }

            transport = {
              respondingTimeouts = {
                readTimeout = "600s" # These must be set as Immich may upload large videos taking more than the default 60s
                idleTimeout = "600s"
              }
            }
          }
        }

        websecure = {
          port = 443

          http = {
            transport = {
              respondingTimeouts = {
                readTimeout = "600s" # These must be set as Immich may upload large videos taking more than the default 60s
                idleTimeout = "600s"
              }
            }
          }
        }

        metrics = {
          port     = 9101
          hostPort = 9101
        }
      }

      logs = {
        general = {
          level = "TRACE"
        }
      }

      hostNetwork = true
      service = {
        enabled = false
      }

      certificatesResolvers = {
        cloudflare = {
          acme = {
            email   = "shearman.cloudflare@zak.pink"
            storage = "/data/acme.json"
            dnsChallenge = {
              provider = "cloudflare"
            }
          }
        }
      }

      securityContext = {
        readOnlyRootFilesystem = false
        runAsGroup             = 0
        runAsUser              = 0
        runAsNonRoot           = false

        capabilities = {
          drop = ["ALL"]
          add  = ["NET_BIND_SERVICE"]
        }
      }

      persistence = {
        enabled = true
        name    = "traefik"
      }

      envFrom = [
        {
          secretRef = {
            name = local.traefik_cf_secret_name
          }
        }
      ]
    })
  ]

  depends_on = [kubernetes_namespace_v1.traefik, kubernetes_secret_v1.traefik_cf_api_key]
}
