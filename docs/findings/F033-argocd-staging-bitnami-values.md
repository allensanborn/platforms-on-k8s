# F033: Chapter-4 staging config used Bitnami value paths and a stale manifest dump

- **Chapter:** 4
- **Severity:** high
- **Status:** fixed
- **Fix commit:** fa1df29
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

- `staging/Chart.yaml` depended on `oci://docker.io/salaboy` `conference-app` `v1.0.0` (Bitnami images, [F002](F002-published-chart-embeds-bitnami.md)).
- `values-debug-enabled.yaml` set `redis.auth.existingSecret` / `postgresql.auth.existingSecret`. Those are Bitnami value paths, used to stop regenerated random passwords from breaking the app on upgrade.
- `staging-kube/app.yaml` was a 2023 `helm template` dump of the Bitnami subcharts.

## Root cause

F001/F002.

## Evidence

- `helm dependency update chapter-4/argo-cd/staging` (with local registry credentials), then `helm install staging-environment chapter-4/argo-cd/staging -n staging`: all pods Running with 0 restarts.
- `helm upgrade … -f values-debug-enabled.yaml`: `/api/features/` → `{"DebugEnabled":"true",…}`.
- Argo CD v3.5.3 Application on this fork's branch, path `chapter-4/argo-cd/staging-kube`: `Synced Healthy`, e2e passed (after the [F007](F007-kafka-bootstrap-timeout-on-kind.md) stall).

## Fix or workaround

- Chart dependency is now `oci://ghcr.io/allensanborn` `conference-app` `v1.1.0`.
- `values-debug-enabled.yaml` only sets `conference-app.services.frontend.debug: true`. The new chart creates fixed-value Secrets, so no `existingSecret` is needed.
- `staging-kube/app.yaml` is regenerated with `helm template conference conference-application/helm/conference-app --skip-tests`.
- `staging/.gitignore` ignores `charts/` and `Chart.lock`.
- After the package went public, an Argo CD Application for path `chapter-4/argo-cd/staging/` on this branch reached `Synced Healthy` on cluster `pek-final`: 8 pods with 0 restarts, and e2e passed. Switching the Application to `values-debug-enabled.yaml` rolled the frontend, and `/api/features/` then returned `"DebugEnabled":"true"`.

## How to verify

Create the Argo CD Application from the README (path `chapter-4/argo-cd/staging/`, this branch) once the package is public.

## Upstream relevance

Yes, together with F002.
