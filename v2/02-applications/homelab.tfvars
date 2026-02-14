cluster_name = "project-a"

kubeconfig_path    = "~/.kube/config"
kubeconfig_context = "k8s-project-a-1.tailf7a2e5.ts.net"

longhorn_namespace = "longhorn-system"
longhorn_version   = "1.8.1"
longhorn_s3_endpoint = "https://s3.eu-central-003.backblazeb2.com"

tailscale_operator_namespace     = "tailscale"
tailscale_operator_chart_version = "1.84.2"

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
    hostname = "grafana.shearman.cloud"
    service_uri = "http://kube-prometheus-stack-grafana.monitoring.svc.cluster.local:80"
  }
]

immich_namespace     = "immich"
immich_version       = "v2.5.6"
immich_chart_version = "0.10.3"

traefik_namespace = "traefik"
traefik_version   = "39.0.1"

openspeedtest_namespace     = "speedtest"
openspeedtest_chart_version = "0.1.2"

kubescape_namespace = "kubescape"
kubescape_chart_version   = "1.27.5"

kube_prometheus_stack_version = "81.6.9"

# plane_namespace = "plane"
# plane_chart_version = "1.1.1"