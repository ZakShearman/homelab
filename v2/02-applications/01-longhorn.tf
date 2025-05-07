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

  values = [
    yamlencode({
      persistence = {
        // There is only a single node, so this has to be 1 for now
        defaultClassReplicaCount = 1
      }
    })
  ]

  wait = true
  # If the install fails, automatically roll back
  atomic  = true
  timeout = 180 # 3 minutes

  depends_on = [kubernetes_namespace.longhorn]
}