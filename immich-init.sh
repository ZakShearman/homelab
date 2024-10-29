helm install immich immich/immich --namespace immich-system --version 0.8.3 -f immich-values.yaml --wait

# helm upgrade immich immich/immich --namespace immich-system --version 0.8.3 -f immich-values.yaml --wait