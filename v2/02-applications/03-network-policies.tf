# TODO: also define egress rules to make exfiltration and lateral movement harder

resource "kubernetes_network_policy" "openspeedtest_default_ingress" {
  metadata {
    name      = "openspeedtest-default-ingress"
    namespace = kubernetes_namespace.speedtest.metadata[0].name
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    policy_types = ["Ingress"]

    pod_selector {
      match_labels = {} # Select all pods in the namespace
    }
  }

  depends_on = [kubernetes_namespace.speedtest]
}

resource "kubernetes_network_policy" "openspeedtest_default_egress" {
  metadata {
    name      = "openspeedtest-default-egress"
    namespace = kubernetes_namespace.speedtest.metadata[0].name
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  spec {
    policy_types = ["Egress"]

    pod_selector {
      match_labels = {} # Select all pods in the namespace
    }
  }

  depends_on = [kubernetes_namespace.speedtest]
}