resource "kubernetes_namespace" "metallb_namespace" {
  metadata {
    name = "metallb-system"
    labels = {
      "pod-security.kubernetes.io/enforce" = "privileged"
      "pod-security.kubernetes.io/audit"   = "privileged"
      "pod-security.kubernetes.io/warn"    = "privileged"
    }
  }
}

resource "helm_release" "metallb_install" {
  depends_on = [kubernetes_namespace.metallb_namespace]

  name       = "metallb"
  repository = "https://metallb.github.io/metallb"
  chart      = "metallb"
  namespace  = "metallb-system"
  version = "0.14.8"
  # We must wait so the CRDs are created and webhooks are listening before creating any CRDs
  wait       = true
}

resource "kubectl_manifest" "metallb_config_pool" {
  depends_on = [helm_release.metallb_install]

  yaml_body = <<YAML
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
    name: server-pool
    namespace: metallb-system
spec:
    addresses:
    - "10.0.40.20-10.0.40.100"
  YAML
}

resource "kubectl_manifest" "metallb_config_advertisement" {
  depends_on = [kubectl_manifest.metallb_config_pool]

  yaml_body = <<YAML
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
    name: server-pool
    namespace: metallb-system
spec:
    ipAddressPools:
    - server-pool
  YAML
}

resource "null_resource" "metallb_complete" {
  depends_on = [
    kubectl_manifest.metallb_config_advertisement
  ]
}