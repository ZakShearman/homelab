resource "kubernetes_namespace" "cnpg" {
  metadata {
    name = var.cnpg_operator_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

resource "helm_release" "cnpg" {
  name       = "cnpg-operator"
  repository = "https://cloudnative-pg.github.io/charts"
  chart      = "cloudnative-pg"
  namespace  = var.cnpg_operator_namespace
  version = var.cnpg_operator_version

  # We create it manually above
  create_namespace = false

  wait = true
  # If the install fails, automatically roll back
  atomic  = true
  timeout = 60 # 1 minute

  depends_on = [helm_release.longhorn, kubernetes_namespace.cnpg]
}
