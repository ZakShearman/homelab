locals {
  cloudflare_secret_name = "cloudflare-tunnel-secret"
}

resource "kubernetes_namespace_v1" "cloudflare" {
  metadata {
    name = "cloudflared"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_secret_v1" "cloudflare_tunnel_secret" {
  metadata {
    name      = local.cloudflare_secret_name
    namespace = kubernetes_namespace_v1.cloudflare.metadata[0].name
  }

  data = {
    "credentials.json" = data.sops_file.cloudflare_tunnel.raw
  }

  type = "Opaque"

  depends_on = [kubernetes_namespace_v1.cloudflare, data.sops_file.cloudflare_tunnel]
}

resource "helm_release" "cloudflared_tunnel" {
  name       = "cloudflared"
  repository = "https://cloudflare.github.io/helm-charts"
  chart      = "cloudflare-tunnel"
  namespace  = kubernetes_namespace_v1.cloudflare.metadata[0].name
  version    = var.cloudflared_helm_chart_version

  values = [
    yamlencode({
      cloudflare = {
        account    = data.sops_file.secrets.data["cloudflare_account_id"]
        tunnelName = var.cloudflare_tunnel_name
        tunnelId   = data.sops_file.secrets.data["cloudflare_tunnel_id"]
        secretName = local.cloudflare_secret_name # Uses the variable (defaults to cloudflare-tunnel-secret)

        ingress = [
          for svc in var.cloudflare_tunnel_svcs : {
            hostname = svc.hostname
            service  = svc.service_uri # Renaming happens here
          }
        ]
      }
      image = {
        tag = var.cloudflared_version
      }
      # Add any other Helm values you might need here
    })
  ]

  depends_on = [kubernetes_secret_v1.cloudflare_tunnel_secret, data.sops_file.secrets]

  wait = true
  # If the install fails, automatically roll back
  atomic  = true
  timeout = 60 # 1 minute
}
