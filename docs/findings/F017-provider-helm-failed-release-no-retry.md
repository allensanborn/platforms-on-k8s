# F017: A provider-helm Release whose first install fails stays `failed`

- **Chapter:** 6
- **Severity:** medium
- **Status:** fixed
- **Fix commit:** b2ee1fc, 07d8fa2
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`Release "conference" failed: … failed calling webhook "mcluster.cnpg.io": … connection refused` and the Release stays `STATE failed`, `READY False`.

## Root cause

Two things combine:
- The app Release installs concurrently with the CNPG operator inside the vcluster, and CNPG's webhook isn't serving yet.
- provider-helm only retries a failed release when `rollbackLimit` is set, and even then only on its next poll. The poll interval defaults to **10m** (`--poll`, `cmd/provider/main.go` at v1.4.0).

## Evidence

Cluster `pek-final`, 2026-09-30:
- With `rollbackLimit: 3` and the default poll, the team-b Environment's app Release stayed `failed` for over 10 minutes. There was one `UpdatedExternalResource` event about 1 minute after the failure, then nothing.
- After setting `--poll=1m` on provider-helm, a new team-c Environment went from failure (`server-side apply failed … mcluster.cnpg.io`) to `UpdatedExternalResource` 1 minute later, then `CreatedExternalResource` about 70 seconds after that. The Environment was `READY` 5m40s after creation.

## Fix or workaround

- `rollbackLimit: 3` on the app Release (commit b2ee1fc).
- `--poll=1m` for provider-helm through its `DeploymentRuntimeConfig` (`deploymentTemplate` → container `package-runtime` → `args`) in `chapter-5/crossplane/helm-provider.yaml`.

## How to verify

Fresh Environment reaches `READY True` without manual action.

## Upstream relevance

Yes.

