resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "kubernetes_config_map" "grafana_cloudflare_auth" {
  metadata {
    name = "grafana-cloudflare-auth"
    namespace = kubernetes_namespace.monitoring.metadata[0].name
  }

  data = {
    GF_AUTH_PROXY_ENABLED = "true"
    GF_AUTH_PROXY_HEADER_NAME = "Cf-Access-Authenticated-User-Email"
    GF_AUTH_PROXY_AUTO_SIGN_UP = "true"
    GF_USERS_AUTO_ASSIGN_ORG_ROLE = "Admin"
  }

  depends_on = [kubernetes_namespace.monitoring]
}

resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name
  version = var.kube_prometheus_stack_version

  # We create it manually above
  create_namespace = false

  values = [file("files/prom-stack-values.yaml")]

  # Appears to not work correctly, so we must disable wait and atomic. Sadge.
  wait = false
  atomic = false
  timeout = 120 # 2 minutes

  depends_on = [helm_release.longhorn, kubernetes_namespace.monitoring, kubernetes_config_map.grafana_cloudflare_auth]
}
