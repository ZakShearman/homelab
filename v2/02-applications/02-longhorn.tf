resource "kubernetes_namespace_v1" "longhorn" {
  metadata {
    name = "longhorn-system"
    labels = {
      "app.kubernetes.io/managed-by"       = "terraform"
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "longhorn" {
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  namespace  = kubernetes_namespace_v1.longhorn.metadata[0].name
  version    = var.longhorn_version

  values = [
    yamlencode({
      persistence = {
        // There is only a single node, so this has to be 1 for now
        defaultClassReplicaCount = 1
      }

      defaultSettings = {
        backupConcurrentLimit = 10
      }

      defaultBackupStore = {
        backupTarget                 = "cifs://${data.sops_file.secrets.data["hetzner_storage_cifs_addr"]}/backup"
        backupTargetCredentialSecret = kubernetes_secret_v1.longhorn_smb_backups.metadata[0].name
        pollInterval                 = "3600" # 1 hour
      }
    })
  ]

  wait = true
  # If the install fails, automatically roll back
  atomic  = true
  timeout = 180 # 3 minutes

  depends_on = [kubernetes_namespace_v1.longhorn]
}

resource "kubernetes_secret_v1" "longhorn_smb_backups" {
  metadata {
    name      = "longhorn-smb-creds"
    namespace = kubernetes_namespace_v1.longhorn.metadata[0].name
  }

  type = "Opaque"

  data = {
    CIFS_USERNAME = data.sops_file.secrets.data["hetzner_storage_cifs_username"]
    CIFS_PASSWORD = data.sops_file.secrets.data["hetzner_storage_cifs_password"]
  }
}

resource "kubectl_manifest" "longhorn_daily_backup" {
  yaml_body = file("files/longhorn-daily-backup.yaml")

  depends_on = [kubernetes_namespace_v1.longhorn, helm_release.longhorn]
}

# Removed coz not running locally any more
# resource "kubectl_manifest" "longhorn_ingressroute" {
#   yaml_body = yamlencode({
#     apiVersion = "traefik.io/v1alpha1"
#     kind       = "IngressRoute"
#
#     metadata = {
#       name      = "longhorn"
#       namespace = kubernetes_namespace_v1.longhorn.metadata[0].name
#       annotations = {
#         "app.kubernetes.io/managed-by" = "terraform"
#       }
#     }
#
#     spec = {
#       entryPoints = ["websecure"]
#       routes = [
#         {
#           kind  = "Rule"
#           match = "Host(`longhorn.shearman.cloud`)"
#           services = [
#             {
#               name = "longhorn-frontend"
#               port = 80
#             }
#           ]
#         }
#       ]
#       tls = {
#         certResolver = "cloudflare"
#       }
#     }
#   })
#
#   depends_on = [helm_release.traefik]
# }
