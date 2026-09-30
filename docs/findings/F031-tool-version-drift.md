# F031: Tool versions drifted in chapters not updated here

- **Chapter:** 4, 7, 8, 9
- **Severity:** info
- **Status:** documented (table)
- **Fix commit:** —
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

Chapters pin 2023-era versions (ingress-nginx from `main`, Tekton, Argo CD, Knative, Argo Rollouts, Dapr, Keptn).

## Root cause

Age.

## Evidence

Checked 2026-09-30:

| Tool | Pinned in tutorial | Latest seen | Worked as pinned? |
| --- | --- | --- | --- |
| ingress-nginx | `main` manifest (controller v1.15.1) | same | needs nodeSelector patch ([F004](F004-ingress-nginx-kind-nodeselector.md)) |
| Crossplane | 1.15.0 | 2.4.2 (CLI 2.5.0) | no; rewritten for v2 ([F012](F012-crossplane-v2-compositions.md)) |
| provider-helm | v0.17.0 | v1.4.0 | updated |
| vcluster | 0.15.7 | 0.37.2 | no; updated ([F014](F014-vcluster-values-schema.md)) |
| Argo CD | `stable` | v3.5.3 | yes with `--server-side` ([F032](F032-argocd-client-side-apply-too-long.md)) |
| Knative Serving / Kourier | knative-v1.10.2 / v1.10.0 | knative-v1.23.0 | yes, left pinned ([F036](F036-chapter8-name-clash-and-knative-drift.md)) |
| Knative Eventing | knative-v1.11.0 | not checked | yes, left pinned |
| Argo Rollouts | `latest` | v1.10.0 | yes with `--server-side` ([F035](F035-argo-rollouts-client-side-apply.md)) |
| Sockeye | v0.7.0 | not checked | yes |
| Keptn | `klt` chart (0.2.6) | `keptn` 0.11.0 | not run ([F038](F038-keptn-klt-chart-renamed.md)) |
| Dapr (chapter 7) | see chapter 7 | not checked | see chapter-7 findings |
| Tekton / Dagger (pipelines) | `alpine/helm:3.12.1`, 2023 Dagger SDK | not checked | not run |

## Fix or workaround

None yet.

## How to verify

n/a

## Upstream relevance

Yes.

