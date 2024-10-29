resource "kubernetes_namespace" "immich_namespace" {
  metadata {
    name = "immich-system"
  }
}

resource "kubernetes_persistent_volume_claim" "immich_pvc" {
  depends_on = [kubernetes_namespace.immich_namespace]

  metadata {
    name      = "immich-pvc"
    namespace = "immich-system"
  }

  spec {
    access_modes = ["ReadWriteMany"]
    resources {
      requests = {
        storage = "50Gi"
      }
    }
  }
}

# TODO not working :\ - Might be fixed now I updated the Helm Terraform provider. It fixed it for Coder
# resource "helm_release" "immich_install" {
#   depends_on = [kubernetes_persistent_volume_claim.immich_pvc]
#
#   name       = "immich"
#   repository = "https://immich-app.github.io/immich-charts"
#   chart      = "immich"
#   namespace  = "immich-system"
#   version    = "0.8.3"
#
#   wait = true
#
#   values = [
#     file("immich-values.yaml")
#   ]
# }

resource "kubectl_manifest" "immich_load_balancer" {
  depends_on = [kubernetes_namespace.immich_namespace, null_resource.metallb_complete]

  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: immich-frontend-external
  namespace: immich-system
  annotations:
    metallb.universe.tf/loadBalancerIPs: 10.0.40.22
spec:
  type: LoadBalancer
  selector:
    app.kubernetes.io/instance: immich
    app.kubernetes.io/name: server
  ports:
    - port: 80
      targetPort: http
  YAML
}
