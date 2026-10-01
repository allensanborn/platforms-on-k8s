# F049: GHCR image packages weren't linked to the fork repository

- **Chapter:** all
- **Severity:** low
- **Status:** fixed for future pushes; existing packages need a manual link
- **Fix commit:** PENDING
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`gh api '/user/packages?package_type=container'` shows `repository: null` for all 11 image packages and for the `conference-admin` chart. Only the `conference-app` chart is linked to `allensanborn/platforms-on-k8s`.

## Root cause

GHCR links a package from the `org.opencontainers.image.source` annotation on the manifest it receives, which for a multi-arch push is the **index**. `ko build --image-label` only sets the label in each platform image's config. The `conference-admin` chart had no `sources` in `Chart.yaml`, which is what Helm turns into that annotation.

## Evidence

Pushing to a local `registry:2` with ko v0.19.1 and `--image-annotation org.opencontainers.image.source=…` put the annotation on the index (`application/vnd.oci.image.index.v1+json` → `annotations.org.opencontainers.image.source`). The per-platform entries carry none.

## Fix or workaround

- `hack/publish-ghcr.sh` now passes `--image-annotation org.opencontainers.image.source=$SOURCE` as well as the label.
- `conference-admin/helm/conference-admin/Chart.yaml` now has `sources`.
- The already published tags were **not** overwritten, so the 12 existing packages still need linking by hand: open each package's settings → *Connect repository* → `allensanborn/platforms-on-k8s` (no API for this). The next publish of a new tag also carries the annotation.

## How to verify

`gh api '/user/packages?package_type=container' -q '.[] | "\(.name) \(.repository.full_name)"'`.

## Upstream relevance

No.
