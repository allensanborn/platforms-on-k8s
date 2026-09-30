# F044: Inventory of images from salaboy's registry, and their fork replacements

- **Chapter:** all
- **Severity:** high
- **Status:** fixed
- **Fix commit:** f03c06d, cdf1e79, d88feec
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

The tutorials pulled the application from `docker.io/salaboy`, so the fork depended at runtime on artifacts it can't change.

## Root cause

Images were built and pushed by the author's CI (`.github/workflows/*-service-pipeline.yaml`, main only) and by `ko` from a laptop.

## Evidence

`git grep` for `salaboy/` image references on both branches, 2026-09-30:

| Image (book) | Source dir | Consumers | Fork image |
| --- | --- | --- | --- |
| `salaboy/agenda-service-0967…:v1.0.0` | `conference-application/agenda-service` | chart values, `chapter-2/kind-load.sh`, `chapter-4/argo-cd/staging-kube`, `chapter-8/knative`, `service-pipeline.go`, `agenda-service/tests/docker-compose.yaml` | `ghcr.io/allensanborn/agenda-service-0967…:v1.2.0` |
| `salaboy/c4p-service-a3dc…:v1.0.0` | `conference-application/c4p-service` | chart, kind-load, staging-kube, chapter 8 | `…/c4p-service-a3dc…:v1.2.0` |
| `salaboy/frontend-go-1739…:v1.0.0`, `:v1.1.0` | `conference-application/frontend-go` | chart, kind-load, staging-kube, chapter 8 (v1.1.0 demo) | `…/frontend-go-1739…:v1.2.0`, `:v1.3.0` |
| `salaboy/notifications-service-0e27…:v1.0.0`, `:v1.1.0` | `conference-application/notifications-service` | chart, kind-load, staging-kube, chapter 8 Knative and Argo Rollouts | `…/notifications-service-0e27…:v1.2.0`, `:v1.3.0` |
| `salaboy/admin-go-4b13…:v1.0.0` | `conference-admin/admin-go` | `conference-admin` chart (chapter 6) | `…/admin-go-4b13…:v1.2.0` |
| `salaboy/*:v2.0.0` (the 4 services, Dapr line) | same dirs on upstream `v2.0.0` | chapter 7 chart | `…:v2.1.0` from branch `v2.0.0-bitnami-replacements` |
| `salaboy/<fn>.go-<md5>` (6 functions) | `chapter-9/dora-cloudevents/<fn>.go` | `resources/components.yaml` | `ghcr.io/allensanborn/dora-<fn>:v1.2.0` ([F045](F045-ko-single-file-builds.md)) |
| charts `salaboy/conference-app`, `salaboy/conference-admin` | `conference-application/helm/conference-app`, `conference-admin/helm/conference-admin` | chapters 2, 4, 5, 6, 9 | `ghcr.io/allensanborn/conference-app:v1.2.0` (plus `v1.1.0`, `v2.1.0`), `…/conference-admin:v1.2.0` |

References with no image source in this repo, kept as they are:
- `chapter-3/tekton/hello-world` mentions `salaboy/fmtok8s-*` images from the author's earlier book repo.
- Tekton pipelines default `target-registry` to `docker.io/salaboy`. That is a parameter the reader overrides with their own registry.
- `salaboy/cloudevents-knative-test` is a GitHub repo used as an event source.
- The JSON example contains GitHub API URLs.

## Fix or workaround

Every image is rebuilt from this repo with ko (`linux/amd64`, `linux/arm64`). Each is labelled `org.opencontainers.image.source=https://github.com/allensanborn/platforms-on-k8s` and pushed to `ghcr.io/allensanborn` with new tags; no upstream tag number is reused for different content. `hack/publish-ghcr.sh` reproduces this. Digests are in [UPDATE-NOTES.md](../../UPDATE-NOTES.md#published-artifacts).

## How to verify

`git grep -n 'salaboy/[a-z-]*-[0-9a-f]\{32\}' -- ':!*README-*.md' ':!docs/*'` lists nothing on this branch.

## Upstream relevance

Yes: it shows how to republish.
