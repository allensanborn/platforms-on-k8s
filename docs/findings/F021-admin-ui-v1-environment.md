# F021: Admin UI still writes the Crossplane v1 `Environment` shape

- **Chapter:** 6
- **Severity:** medium
- **Status:** fixed
- **Fix commit:** f03c06d (image `ghcr.io/allensanborn/admin-go-4b1308c49d6627e0dc7e3ffd57f155cc:v1.2.0`, chart `conference-admin` v1.2.0)
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`conference-admin/admin-go/api/types/v1alpha1/environment.go` has `spec.compositionSelector` at the root and `writeConnectionSecretToRef`; no namespace handling for a namespaced XR.

## Root cause

Written for v1 claims.

## Evidence

Cluster `pek-admin`, 2026-09-30, with Crossplane v2.4.2, provider-helm v1.4.0, the chapter-6 XRD and Composition, and `helm install admin conference-admin/helm/conference-admin -n team-a`:
- `/api/service/info` reported `"version":"1.2.0"` (the build-time version).
- `POST /api/environments/` with `chapter-6/team-a-dev-env-simple.json` created `team-curl-dev-env` in `team-a`, with `spec.crossplane.compositionSelector.matchLabels.type: development`. Crossplane selected `dev.env.salaboy.com`.
- `GET /api/environments/` returned the v1 fields the UI reads: `spec.compositionSelector`, `spec.resourceRef.name: team-curl-dev-env`, `spec.writeConnectionSecretToRef.name: vc-team-curl-dev-env`, conditions `[Synced, Ready]`. `GET /` returned 200.
- `DELETE /api/environments/team-curl-dev-env` → 200. The Environment and all four Releases were deleted, and the list became `[]`.
- The images were still private, so this run used a temporary pull secret in the throwaway cluster.
- The browser UI itself was not clicked through.

## Fix or workaround

- `api/types/v1alpha1/environment.go`: new `spec.crossplane.compositionSelector`.
- `admin.go`: works on `ENVIRONMENT_NAMESPACE` (chart value `environmentNamespace`, default the release namespace). `withV1Fields` fills in the v1 fields on read, so the prebuilt Next.js UI in `kodata` didn't need rebuilding. Unit test `admin_test.go`.
- Chart: `ClusterRoleBinding` subject namespace is now the release namespace instead of `default`.
- Published as the image and chart above.

## How to verify

n/a

## Upstream relevance

Yes.

