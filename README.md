# Homelab



### K3s Install

`nfs-common` was installed by default on Ubuntu 24.04, but not on Ubuntu 26.04
```shell
apt update && apt upgrade -y && apt install -y nfs-common
```

```shell
mkdir -p /var/lib/rancher/k3s/server && cat > /var/lib/rancher/k3s/server/audit-policy.yaml <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: None
  resources:
  - group: ""
    resources: ["endpoints", "services", "services/status"]
- level: None
  users: ["system:kube-proxy"]
- level: None
  resources:
  - group: ""
    resources: ["events"]
- level: Metadata
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
- level: Metadata
  omitStages:
  - RequestReceived
EOF
```

```shell
curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="v1.36.1+k3s1" K3S_TOKEN="$token" sh -s - server \
  --cluster-init \
  --flannel-backend=none \
  --disable-network-policy \
  --disable-kube-proxy \
  --disable local-storage \
  --bind-address "$tailscale_ip" \
  --advertise-address "$tailscale_ip" \
  --node-name "$node_name" \
  --node-ip "$tailscale_ip" \
  --node-external-ip "$magictransit_ip" \
  --resolv-conf /run/systemd/resolve/resolv.conf \
  --secrets-encryption-provider secretbox \
  --protect-kernel-defaults=true \
  --cluster-cidr=10.42.0.0/16 \
  --service-cidr=10.43.0.0/16 \
  --disable traefik \
  --kube-apiserver-arg audit-policy-file=/var/lib/rancher/k3s/server/audit-policy.yaml \
  --kube-apiserver-arg audit-log-path=/var/log/k3s-audit.log \
  --kube-apiserver-arg tls-min-version=VersionTLS13 \
  --kube-apiserver-arg audit-log-maxage=90 \
  --kube-apiserver-arg audit-log-maxsize=1000 \
  --kube-apiserver-arg audit-log-maxbackup=25
```

`--default-local-storage-path` disables the Longhorn local path provisioner, since I use full Longhorn.