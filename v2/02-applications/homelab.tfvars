cluster_name = "project-a"

kubeconfig_path = "../01-infra/kubeconfig"
kubeconfig_context = "admin@project-a"

longhorn_namespace = "longhorn-system"
longhorn_version = "1.8.1"

tailscale_operator_namespace = "tailscale"
tailscale_operator_chart_version = "1.80.3"

cnpg_operator_namespace = "cnpg-operator"
cnpg_operator_version = "0.23.2"

cloudflared_namespace = "cloudflared"
cloudflared_version = "2025.2.1"
cloudflared_helm_chart_version = "0.3.2" # https://github.com/cloudflare/helm-charts/blob/main/charts/cloudflare-tunnel/Chart.yaml
cloudflare_tunnel_name = "k8s-project-a"

cloudflare_tunnel_svcs = [{
  hostname = "photos.shearman.cloud"
  service_uri = "http://immich-server.immich.svc.cluster.local:2283"
}]

immich_namespace = "immich"
immich_version = "v1.130.2"
immich_chart_version = "0.9.2"

traefik_namespace = "traefik"
traefik_version = "34.4.1"

openspeedtest_namespace = "speedtest"
openspeedtest_chart_version = "0.1.2"