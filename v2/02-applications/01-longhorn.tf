resource "kubernetes_namespace" "longhorn" {
  metadata {
    name = var.longhorn_namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "pod-security.kubernetes.io/enforce" = "privileged"
    }
  }
}

resource "helm_release" "longhorn" {
  name       = "longhorn"
  repository = "https://charts.longhorn.io"
  chart      = "longhorn"
  namespace  = var.longhorn_namespace
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
        backupTarget = "cifs://${data.sops_file.secrets.data["hetzner_storage_cifs_addr"]}/backup"
        backupTargetCredentialSecret = kubernetes_secret.longhorn_smb_backups.metadata[0].name
        pollInterval = "3600" # 1 hour
      }

      # defaultBackupStore = {
      #   backupTarget = "s3://${data.sops_file.secrets.data["longhorn_backblaze_bucket_name"]}@${data.sops_file.secrets.data["longhorn_backblaze_bucket_region"]}/"
      #   backupTargetCredentialSecret = kubernetes_secret.longhorn_backblaze_backups.metadata[0].name
      #   pollInterval = "43200" # 12 hours
      # }
    })
  ]

  wait = true
  # If the install fails, automatically roll back
  atomic = true
  timeout = 180 # 3 minutes

  depends_on = [kubernetes_namespace.longhorn, kubernetes_secret.longhorn_backblaze_backups]
}

resource "kubernetes_secret" "longhorn_backblaze_backups" {
  metadata {
    name      = "longhorn-backup-secret"
    namespace = kubernetes_namespace.longhorn.metadata[0].name
  }

  type = "Opaque"

  data = {
    AWS_ACCESS_KEY_ID     = data.sops_file.secrets.data["longhorn_backblaze_access_key_id"]
    AWS_SECRET_ACCESS_KEY = data.sops_file.secrets.data["longhorn_backblaze_secret_access_key"]
    AWS_ENDPOINTS         = var.longhorn_s3_endpoint
  }

  depends_on = [var.longhorn_namespace, data.sops_file.secrets]
}

resource "kubernetes_secret" "longhorn_smb_backups" {
  metadata {
    name = "longhorn-smb-creds"
    namespace = kubernetes_namespace.longhorn.metadata[0].name
  }
  
  type = "Opaque"
  
  data = {
    CIFS_USERNAME = data.sops_file.secrets.data["hetzner_storage_cifs_username"]
    CIFS_PASSWORD = data.sops_file.secrets.data["hetzner_storage_cifs_password"]
  }
}

resource "kubectl_manifest" "backblaze_daily_backup" {
  yaml_body = file("files/longhorn-daily-backup.yaml")

  depends_on = [kubernetes_namespace.longhorn, helm_release.longhorn]
}
