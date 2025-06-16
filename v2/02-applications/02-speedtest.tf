resource "kubernetes_namespace" "speedtest" {
  metadata {
    name = var.openspeedtest_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "speedtest" {
  name       = "speedtest"
  repository = "https://openspeedtest.github.io/Helm-chart/"
  chart      = "openspeedtest"
  namespace  = var.openspeedtest_namespace
  version = var.openspeedtest_chart_version

  # We create it manually above
  create_namespace = false

  wait   = true
  atomic = true
  timeout = 60 # 1 minute

  values = [
    yamlencode({
      service = {
        type = "ClusterIP"
      }

      securityContext = {
        # readOnlyRootFilesystem = true
        # runAsNonRoot           = true
        # runAsGroup             = 1000
        # runAsUser              = 1000
        # privileged             = false
      }

      resources = {
        limits = {
          memory = "128Mi"
          cpu    = "1"
        }
      }
    })
  ]

  depends_on = [kubernetes_namespace.speedtest]
}

# resource "kubectl_manifest" "speedtest_middleware_https_redirect" {
#   yaml_body = yamlencode({
#     apiVersion = "traefik.containo.us/v1alpha1"
#     kind = "Middleware"
#
#     metadata = {
#       name = "redirect-https"
#       namespace = var.openspeedtest_namespace
#
#         annotations = {
#             "app.kubernetes.io/managed-by" = "terraform"
#         }
#     }
#
#     spec = {
#       redirectScheme = {
#         scheme = "https"
#         permanent = true
#       }
#     }
#   })
# }

resource "kubectl_manifest" "speedtest_buffer_middleware" {
  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "Middleware"

    metadata = {
      name      = "openspeedtest-buffer"
      namespace = var.openspeedtest_namespace
      annotations = {
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }

    spec = {
      buffering = {
        # OpenSpeedTest recommends 35 MiB for the buffer size
        maxRequestBodyBytes = 36700160 # 35 MiB
        maxResponseBodyBytes = 36700160 # 35 MiB
      }
    }
  })

  depends_on = [helm_release.speedtest, kubernetes_namespace.speedtest]
}

resource "kubectl_manifest" "speedtest_ingressroute" {
  yaml_body = yamlencode({
    apiVersion = "traefik.io/v1alpha1"
    kind       = "IngressRoute"

    metadata = {
      name      = "openspeedtest"
      namespace = var.openspeedtest_namespace
      annotations = {
        "app.kubernetes.io/managed-by" = "terraform"
      }
    }

    spec = {
      entryPoints = ["websecure"]
      routes = [
        {
          kind  = "Rule"
          match = "Host(`speed.shearman.cloud`)"
          services = [
            {
              name = "speedtest-openspeedtest"
              port = 3000
            }
          ]
          middlewares = [
            {
              name      = "openspeedtest-buffer"
              namespace = kubernetes_namespace.speedtest.metadata[0].name
            }
          ]
        }
      ]
      tls = {
        certResolver = "cloudflare"
      }
    }
  })

  depends_on = [kubernetes_namespace.speedtest, helm_release.traefik, kubectl_manifest.speedtest_buffer_middleware]
}