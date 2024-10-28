helm repo add nextcloud https://nextcloud.github.io/helm/
helm repo update nextcloud

helm install nextcloud nextcloud/nextcloud \
    --version 6.2.1 \
    --namespace nextcloud --create-namespace \
    --set nextcloud.password=test \
    --set nextcloud.host=10.0.40.5 \
    --set service.type=NodePort
