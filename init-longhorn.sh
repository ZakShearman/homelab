helm repo add longhorn https://charts.longhorn.io
helm repo update longhorn

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: longhorn-system
  labels:
    pod-security.kubernetes.io/enforce: privileged
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: privileged
    pod-security.kubernetes.io/audit-version: latest
    pod-security.kubernetes.io/warn: privileged
    pod-security.kubernetes.io/warn-version: latest
EOF

helm install longhorn longhorn/longhorn --namespace longhorn-system --version 1.7.2
