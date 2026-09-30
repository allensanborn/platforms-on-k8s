# F060: Keptn is archived; the chapter-9 Keptn tutorial now uses Argo CD, Argo Rollouts, Prometheus/Grafana and Jaeger v2

- **Chapter:** 9 (keptn)
- **Severity:** high
- **Status:** fixed
- **Fix commit:** see branch `keptn-current`
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`
- **Supersedes:** [F038](F038-keptn-klt-chart-renamed.md), [F040](F040-keptn-observability-stack.md)

## Symptom

`chapter-9/keptn` installed the frozen `klt` chart (F038), and its observability stack never came up because jaeger-operator v1.45 doesn't reconcile a `Jaeger` CR (F040).

## Root cause

The project itself is gone:

- Keptn's maintainers asked the CNCF to archive the project: "The major maintaining company has stepped back from the project, and Keptn is currently in maintenance mode … Most maintainers are inactive". The TOC vote passed 9-0 on 2025-09-03, and archiving (landscape, CLOMonitor, DevStats, maintainer lists) was completed on 2025-09-08: https://github.com/cncf/toc/issues/1584.
- Last release: `keptn-v2.5.0` / `metrics-operator-v2.1.0`, 2025-03-19. Helm repo https://charts.lifecycle.keptn.sh: `keptn` 0.11.0 is the newest chart, and `klt` stopped at 0.2.6 (2023-09-07).
- The last human commit on `keptn/lifecycle-toolkit` `main` is from 2025-08-06. Since then there are only unmerged renovate PRs. The GitHub repository isn't archived, and its README still says "incubating".

Moving to `keptn` 0.11.0 would have meant teaching a tool with no maintainers.

## Fix or workaround

The tutorial was rewritten (the user chose this option) on tools the book already installs:

| Book point (section 9.3) | Keptn | Now |
| --- | --- | --- |
| Deployment frequency / duration without app changes | Keptn metrics + "Keptn Applications" dashboard | Argo CD `argocd_app_sync_total` and `argocd_app_sync_duration_seconds_total`, scraped by kube-prometheus-stack, and a Grafana dashboard (`observability/grafana-dashboard.yaml`) |
| Trace of a rollout | lifecycle-operator → OTel collector → Jaeger (operator) | Argo CD controller OTLP → Jaeger v2 all-in-one (`observability/jaeger.yaml`); needs Argo CD 3.6 ([F062](F062-argocd-sync-traces-need-3-6.md)) |
| Post-deployment task | `KeptnTaskDefinition` + `keptn.sh/post-deployment-tasks` | Argo CD `PostSync` hook Job (`hooks/post-sync-notification.yaml`) |
| Evaluations gate | `KeptnEvaluationDefinition` | Argo Rollouts `AnalysisTemplate` on a Prometheus memory query (`gates/`) |

Lead time for changes isn't covered: Argo CD's metrics have no commit timestamp. The README points to the CloudEvents/CDEvents tutorial in the same chapter.

Not changed (outside `chapter-9/keptn/`): `chapter-9/README*.md` still list the tutorial as "Keptn Lifecycle Toolkit", and their "Sum up" paragraph still describes Keptn. The translated `chapter-9/keptn/README-{es,ja,zh}.md` only got an "out of date" banner ([F041](F041-translated-readmes-stale.md)).

## How to verify

Follow `chapter-9/keptn/README.md` on a fresh kind cluster. Test evidence is in the commit that closes this finding.

## Upstream relevance

Yes. Upstream salaboy/platforms-on-k8s still points at Keptn.
