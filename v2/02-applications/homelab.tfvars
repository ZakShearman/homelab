cluster_name = "project-a"

kubeconfig_path    = "../01-infra/kubeconfig"
kubeconfig_context = "admin@project-a"

longhorn_namespace = "longhorn-system"
longhorn_version   = "1.8.1"

tailscale_operator_namespace     = "tailscale"
tailscale_operator_chart_version = "1.82.5"

cnpg_operator_namespace = "cnpg-operator"
cnpg_operator_version   = "0.23.2"

cloudflared_namespace  = "cloudflared"
cloudflared_version    = "2025.4.2"
cloudflared_helm_chart_version = "0.3.2" # https://github.com/cloudflare/helm-charts/blob/main/charts/cloudflare-tunnel/Chart.yaml
cloudflare_tunnel_name = "k8s-project-a"

cloudflare_tunnel_svcs = [
  {
    hostname    = "photos.shearman.cloud"
    service_uri = "http://immich-server.immich.svc.cluster.local:2283"
  },
  {
    hostname    = "firefly.shearman.cloud"
    service_uri = "http://firefly-iii.firefly.svc.cluster.local:80"
  }
]

immich_namespace     = "immich"
immich_version       = "v1.132.3"
immich_chart_version = "0.9.3"

traefik_namespace = "traefik"
traefik_version   = "35.2.0"

openspeedtest_namespace     = "speedtest"
openspeedtest_chart_version = "0.1.2"

firefly_namespace     = "firefly"
firefly_chart_version = "0.8.2"