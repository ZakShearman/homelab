resource "kubernetes_namespace" "tailscale" {
  metadata {
    name = var.tailscale_operator_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "tailscale_operator" {
  name       = "tailscale-operator"
  repository = "https://pkgs.tailscale.com/helmcharts"
  chart      = "tailscale-operator"
  namespace  = var.tailscale_operator_namespace
  version = var.tailscale_operator_chart_version

  # We create it manually above
  create_namespace = false

  wait = true
  # If the install fails, automatically roll back
  atomic  = true
  timeout = 60 # 1 minute

  set {
    name  = "operatorConfig.hostname"
    value = "k8s-${var.cluster_name}"
  }

  set {
    name = "apiServerProxyConfig.mode"
    type = "string"
    value = "true"
  }

  set_sensitive {
    name  = "oauth.clientId"
    value = data.sops_file.secrets.data["tailscale_operator_client_id"]
  }

  set_sensitive {
    name  = "oauth.clientSecret"
    value = data.sops_file.secrets.data["tailscale_operator_client_secret"]
  }

  depends_on = [kubernetes_namespace.tailscale, data.sops_file.secrets]
}