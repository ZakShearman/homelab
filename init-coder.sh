helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update bitnami

helm install coder-db bitnami/postgresql \
    --namespace coder  --create-namespace \
    --set auth.username=coder \
    --set auth.password=coder \
    --set auth.database=coder \
    --set persistence.size=10Gi

kubectl create secret generic coder-db-url -n coder \
  --from-literal=url="postgres://coder:coder@coder-db-postgresql.coder.svc.cluster.local:5432/coder?sslmode=disable"


helm repo add coder-v2 https://helm.coder.com/v2
helm repo update coder-v2

helm install coder coder-v2/coder \
    --namespace coder \
    --values coder-values.yaml \
    --version 2.15.0
