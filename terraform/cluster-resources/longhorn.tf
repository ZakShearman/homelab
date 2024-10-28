resource "kubernetes_namespace" "longhorn_namespace" {
  metadata {
    name = "longhorn-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/enforce-version" = "latest"
      "pod-security.kubernetes.io/audit" = "privileged"
      "pod-security.kubernetes.io/audit-version" = "latest"
      "pod-security.kubernetes.io/warn" = "privileged"
      "pod-security.kubernetes.io/warn-version" = "latest"
    }
  }
}

resource "helm_release" "longhorn_install" {
  depends_on = [kubernetes_namespace.longhorn_namespace]

  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  namespace  = "longhorn-system"
  version = "1.7.2"

  wait = true
}

# Doesn't need to depend on the helm chart, it will work lazily once its resources are deployed.
resource "kubectl_manifest" "longhorn_load_balancer" {
  depends_on = [kubernetes_namespace.longhorn_namespace, null_resource.metallb_complete]

  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: longhorn-frontend-external
  namespace: longhorn-system
  annotations:
    metallb.universe.tf/loadBalancerIPs: 10.0.40.21
spec:
  type: LoadBalancer
  selector:
    app: longhorn-ui
  ports:
    - port: 80
      targetPort: http
  YAML
}

