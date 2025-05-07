resource "kubernetes_namespace" "longhorn" {
  metadata {
    name = var.longhorn_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "pod-security.kubernetes.io/enforce": "privileged"
    }
  }
}

resource "helm_release" "longhorn" {
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  namespace  = var.longhorn_namespace
  version    = var.longhorn_version

  # values = [
  #   yamlencode({
  #
  #   })
  # ]

  wait = true
  # If the install fails, automatically roll back
  atomic  = true
  timeout = 180 # 3 minutes

  depends_on = [kubernetes_namespace.longhorn]
}