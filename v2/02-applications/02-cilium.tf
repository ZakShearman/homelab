resource "kubernetes_namespace_v1" "cilium" {
  metadata {
    name = "cilium"

    labels = {
      "pod-security.kubernetes.io/enforce" : "privileged",
      "pod-security.kubernetes.io/audit" : "privileged",
      "pod-security.kubernetes.io/warn" : "privileged",
    }
  }
}

resource "helm_release" "cilium" {
  name       = "cilium"
  repository = "https://helm.cilium.io/"
  chart      = "cilium"
  namespace  = "cilium"
  version    = "1.19.4"

  create_namespace = false # should be created due to existing manual install

  values = [
    file("files/cilium-values.yaml")
  ]

  wait    = true
  atomic  = true
  timeout = 300

  max_history = 5

  depends_on = [kubernetes_namespace_v1.cilium]
}
