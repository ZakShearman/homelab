# # Kubescape is a security scanner for Kubernetes clusters.
#
# resource "kubernetes_namespace" "kubescape" {
#   metadata {
#     name = var.kubescape_namespace
#     labels = {
#       "app.kubernetes.io/managed-by" = "terraform"
#     }
#   }
# }
#
# resource "helm_release" "kubescape" {
#   name       = "kubescape-operator"
#   repository = "https://kubescape.github.io/helm-charts/"
#   chart      = "kubescape-operator"
#   namespace  = kubernetes_namespace.kubescape.metadata[0].name
#   version = var.kubescape_chart_version
#
#   # We create it manually above
#   create_namespace = false
#
#   # Kubescape doesn't correctly test install and always fails, so atomic and wait must be false.
#   wait = false
#   atomic  = false
#   timeout = 60 # 1 minute
#
#   depends_on = [kubernetes_namespace.kubescape]
# }