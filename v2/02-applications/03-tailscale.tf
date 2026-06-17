resource "kubernetes_namespace_v1" "tailscale" {
  metadata {
    name = "tailscale"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "tailscale_operator" {
  name       = "tailscale-operator"
  repository = "https://pkgs.tailscale.com/helmcharts"
  chart      = "tailscale-operator"
  namespace  = kubernetes_namespace_v1.tailscale.metadata[0].name
  version    = var.tailscale_operator_chart_version

  # We create it manually above
  create_namespace = false

  wait = true
  # If the install fails, automatically roll back
  atomic  = true
  timeout = 60 # 1 minute

  values = [
    yamlencode({
      operatorConfig = {
        hostname = "k8s-${var.cluster_name}"
      }
      apiServerProxyConfig = {
        mode = "true"
      }
    })
  ]

  set_sensitive {
    name  = "oauth.clientId"
    value = data.sops_file.secrets.data["tailscale_operator_client_id"]
  }

  set_sensitive {
    name  = "oauth.clientSecret"
    value = data.sops_file.secrets.data["tailscale_operator_client_secret"]
  }

  depends_on = [kubernetes_namespace_v1.tailscale, data.sops_file.secrets]
}
