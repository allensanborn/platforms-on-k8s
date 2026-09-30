#!/usr/bin/env bash
# Rebuild and publish this fork's container images and Helm charts to GHCR.
#
#   hack/publish-ghcr.sh main   # run on branch crossplane-v2-and-bitnami-replacements
#   hack/publish-ghcr.sh dapr   # run on branch v2.0.0-bitnami-replacements (chapter 7)
#
# Needs: ko, helm, docker (for the existence check), gh (logged in with write:packages).
# Never overwrites: any image or chart tag that already exists is skipped.
# New GHCR packages are PRIVATE; make each one public in its package settings
# (github.com/users/<owner>/packages/container/package/<name>), there is no API for it.
set -euo pipefail

OWNER=${OWNER:-allensanborn}
REPO=ghcr.io/$OWNER
SOURCE=https://github.com/$OWNER/platforms-on-k8s
ROOT=$(git rev-parse --show-toplevel)
MODE=${1:?usage: publish-ghcr.sh main|dapr}

# Keep registry credentials out of ~/.docker: ko, docker and helm read these.
export DOCKER_CONFIG=${DOCKER_CONFIG:-$ROOT/.scratch/docker-config}
export HELM_REGISTRY_CONFIG=${HELM_REGISTRY_CONFIG:-$ROOT/.scratch/helm-registry.json}
mkdir -p "$DOCKER_CONFIG" "$ROOT/.scratch"
gh auth token | ko login ghcr.io -u "$OWNER" --password-stdin >/dev/null
gh auth token | helm registry login ghcr.io -u "$OWNER" --password-stdin >/dev/null

md5hex() { if command -v md5 >/dev/null; then printf %s "$1" | md5; else printf %s "$1" | md5sum | cut -d' ' -f1; fi; }
exists() { docker manifest inspect "$1" >/dev/null 2>&1; }

# ko_publish <dir> <target: . or file.go> <tag>
# ko names images <basename>-<md5 of import path>, the same names the book used.
ko_publish() {
  local dir=$1 target=$2 tag=$3 import name
  if [ "$target" = "." ]; then import=$(cd "$ROOT/$dir" && go list -mod=mod -f '{{.ImportPath}}' .); else import=$target; fi
  name="$(basename "$import")-$(md5hex "$import")"
  if exists "$REPO/$name:$tag"; then echo "skip $REPO/$name:$tag (exists)"; return; fi
  (cd "$ROOT/$dir" && GOFLAGS="-mod=mod -ldflags=-X=main.buildVersion=${tag#v}" KO_DOCKER_REPO=$REPO \
    ko build --platform=linux/amd64,linux/arm64 --tags="$tag" \
      --image-label "org.opencontainers.image.source=$SOURCE" "./$target" | tail -1)
}

# dora_publish <file basename> <tag>
dora_publish() {
  local f=$1 tag=$2 build=$ROOT/.scratch/dora-build
  if exists "$REPO/dora-$f:$tag"; then echo "skip $REPO/dora-$f:$tag (exists)"; return; fi
  rm -rf "$build/dora-$f"; mkdir -p "$build/dora-$f"
  cp "$ROOT/chapter-9/dora-cloudevents/go.mod" "$ROOT/chapter-9/dora-cloudevents/go.sum" "$build/"
  cp "$ROOT/chapter-9/dora-cloudevents/$f.go" "$build/dora-$f/main.go"
  (cd "$build/dora-$f" && GOFLAGS=-mod=mod KO_DOCKER_REPO=$REPO \
    ko build --base-import-paths --platform=linux/amd64,linux/arm64 --tags="$tag" \
      --image-label "org.opencontainers.image.source=$SOURCE" . | tail -1)
}

# chart_publish <chart dir>   (set SKIP_CHARTS=1 to publish images only)
chart_publish() {
  [ -n "${SKIP_CHARTS:-}" ] && { echo "skip chart $1 (SKIP_CHARTS)"; return; }
  local dir=$ROOT/$1 name version out
  name=$(awk '/^name:/{print $2}' "$dir/Chart.yaml"); version=$(awk '/^version:/{print $2}' "$dir/Chart.yaml")
  if helm show chart "oci://$REPO/$name" --version "$version" >/dev/null 2>&1; then echo "skip chart $name $version (exists)"; return; fi
  out=$(mktemp -d "$ROOT/.scratch/chart.XXXXXX")
  helm dependency update "$dir" >/dev/null
  helm package "$dir" -d "$out" >/dev/null
  helm push "$out/$name-$version.tgz" "oci://$REPO"
}

case $MODE in
main)
  for svc in agenda-service c4p-service frontend-go notifications-service; do
    ko_publish conference-application/$svc . v1.2.0
  done
  # second versions for the chapter-8 release-strategy demos (canary, blue-green, tag routing)
  ko_publish conference-application/frontend-go . v1.3.0
  ko_publish conference-application/notifications-service . v1.3.0
  ko_publish conference-admin/admin-go . v1.2.0
  # Chapter 9: each .go file is its own `package main`. Current ko no longer builds single
  # files (ko://file.go), so each one is copied into its own package under .scratch and
  # published as ghcr.io/<owner>/dora-<name>.
  for f in cloudevents-endpoint cdevents-endpoint cloudevents-router deployment-frequency \
           deployment-frequency-endpoint function-api-server-to-service-deployment; do
    dora_publish "$f" v1.2.0
  done
  chart_publish conference-application/helm/conference-app
  chart_publish conference-admin/helm/conference-admin
  ;;
dapr)
  for svc in agenda-service c4p-service frontend-go notifications-service; do
    ko_publish conference-application/$svc . v2.1.0
  done
  chart_publish conference-application/helm/conference-app
  ;;
*) echo "unknown mode $MODE" >&2; exit 1 ;;
esac
