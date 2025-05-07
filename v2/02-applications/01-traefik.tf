locals {
  traefik_cf_secret_name = "cloudflare-api-key"
}

resource "kubernetes_namespace" "traefik" {
  metadata {
    name = var.traefik_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "pod-security.kubernetes.io/enforce": "privileged"
    }
  }
}

resource "kubernetes_secret" "traefik_cf_api_key" {
  metadata {
    name      = local.traefik_cf_secret_name
    namespace = var.traefik_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  data = {
    CLOUDFLARE_EMAIL         = data.sops_file.secrets.data["cloudflare_email"]
    CLOUDFLARE_DNS_API_TOKEN = data.sops_file.secrets.data["cloudflare_dns_api_token"]
  }

  depends_on = [kubernetes_namespace.traefik, data.sops_file.secrets]
}

resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://traefik.github.io/charts"
  chart      = "traefik"
  namespace  = var.traefik_namespace
  version = var.traefik_version

  # We create it manually above
  create_namespace = false
  wait             = false
  # Traefik helm chart doesn't test install correctly and always fails.
  # atomic = true
  timeout = 60 # 1 minute

  values = [
    yamlencode({
      entryPoints = {
        web = {
          # address = ":80"

          http = {
            redirections = {
              entryPoint = {
                to        = "websecure"
                scheme    = "https"
                permanent = true
              }
            }
          }
        }

        # webSecure = {
        #   address = ":443"
        # }
      }

      ports = {
        web = {
          port = 80
          redirect = {
            entryPoint = {
              to        = "websecure"
              scheme    = "https"
              permanent = true
            }
          }
        }
        websecure = {
          port = 443
        }
      }

      logs = {
        general = {
          level = "TRACE"
        }
      }

      hostNetwork = true
      containers = [{
        name = "traefik"
      }]

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
          add = ["NET_BIND_SERVICE"]
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

  depends_on = [kubernetes_namespace.traefik, kubernetes_secret.traefik_cf_api_key]
}

# resource "kubectl_manifest" "traefik_redirect_all_http" {
#   yaml_body = yamlencode({
#     apiVersion = "traefik.io/v1alpha1"
#     kind       = "IngressRoute"
#
#     metadata = {
#       name      = "redirect-all-http"
#       namespace = var.traefik_namespace
#       annotations = {
#         "app.kubernetes.io/managed-by" = "terraform"
#       }
#     }
#
#     spec = {
#       entryPoints = ["web"]
#       routes = [
#         {
#           kind  = "Rule"
#           match = "HostRegexp(`.*\\.shearman\\.cloud`)"
#           services = [
#             {
#               name = "speedtest-openspeedtest"
#               port = 3000
#             }
#           ]
#         }
#       ]
#       tls = {
#         certResolver = "cloudflare"
#       }
#     }
#   })
#
#   depends_on = [helm_release.traefik]
# }