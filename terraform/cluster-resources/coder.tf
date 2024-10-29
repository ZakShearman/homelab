resource "kubernetes_namespace" "coder_namespace" {
  metadata {
    name = "coder-system"
  }
}

resource "helm_release" "coder_db_install" {
  depends_on = [kubernetes_namespace.coder_namespace]

  name       = "coder-db"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "postgresql"
  namespace  = "coder-system"
  version = "16.0.6"

  values = [
    file("coder-db-values.yaml")
  ]

  wait = true
}

resource "kubernetes_secret" "coder_db_secret" {
  depends_on = [helm_release.coder_db_install]

  metadata {
    name      = "coder-db-url"
    namespace = "coder-system"
  }

  data = {
    "url" = "postgres://coder:coder@coder-db-postgresql.coder-system.svc.cluster.local:5432/coder?sslmode=disable"
    }
}

resource "helm_release" "coder_install" {
  depends_on = [helm_release.coder_db_install]

  name       = "coder"
  repository = "https://helm.coder.com/v2"
  chart      = "coder"
  namespace  = "coder-system"
  version = "2.15.0"

  wait = true

  values = [
    file("coder-values.yaml")
  ]
}