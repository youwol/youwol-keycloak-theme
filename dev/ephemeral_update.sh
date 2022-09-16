#!/bin/sh

target_cluster="gke_thematic-grove-252706_us-central1-a_ojos-del-salado"
target_pod="keycloak-0"
target_ns="infra"


# WILL FAILED !!!! keycloak image is missing 'tar'
kubectl cp --cluster "${target_cluster}" \
  --namespace "${target_ns}" \
  theme \
  "${target_pod}":/opt/keycloak/themes/youwol
