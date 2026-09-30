#!/usr/bin/env bash
# Pre-pull and load the images the Conference application and its infrastructure use.
# Bitnami images were replaced by Valkey, CloudNativePG and Strimzi (Sept 2026).
images=(
  docker.io/valkey/valkey:9.1.2
  docker.io/library/busybox:1.37
  ghcr.io/cloudnative-pg/cloudnative-pg:1.30.1
  ghcr.io/cloudnative-pg/postgresql:18.6-system-trixie
  quay.io/strimzi/operator:1.2.0
  quay.io/strimzi/kafka:1.2.0-kafka-4.3.1
  salaboy/frontend-go-1739aa83b5e69d4ccb8a5615830ae66c:v1.0.0
  salaboy/agenda-service-0967b907d9920c99918e2b91b91937b3:v1.0.0
  salaboy/c4p-service-a3dc0474cbfa348afcdf47a8eee70ba9:v1.0.0
  salaboy/notifications-service-0e27884e01429ab7e350cb5dff61b525:v1.0.0
)
for image in "${images[@]}"; do
  docker pull "$image"
  kind load docker-image -n dev "$image"
done
