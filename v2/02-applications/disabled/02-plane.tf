# resource "kubernetes_namespace" "plane" {
#   metadata {
#     name = var.plane_namespace
#     labels = {
#       "app.kubernetes.io/managed-by" = "terraform"
#     }
#   }
# }
#
# resource "helm_release" "plane" {
#   name       = "plane-app"
#   repository = "https://helm.plane.so/"
#   chart      = "plane-ce"
#   namespace  = kubernetes_namespace.plane.metadata[0].name
#   version = var.plane_chart_version
#
#   values = [yamlencode({
#     planeVersion = var.plane_version
#
#     ingress = {
#       enabled = false
#       appHost = "plane.shearman.cloud"
#     }
#   })]
#
#   # We create it manually above
#   create_namespace = false
#
#   wait = true
#   wait_for_jobs = true
#   timeout = 60 # 1 minute
#
#   depends_on = [kubernetes_namespace.plane]
# }