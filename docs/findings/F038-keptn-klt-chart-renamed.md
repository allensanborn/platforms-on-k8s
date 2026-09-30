# F038: Keptn tutorial installs the frozen `klt` chart

- **Chapter:** 9
- **Severity:** medium
- **Status:** documented (untested)
- **Fix commit:** 
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`chapter-9/keptn/Makefile` runs `helm upgrade --install keptn klt/klt` from `https://charts.lifecycle.keptn.sh`.

## Root cause

In that repo the `klt` chart's last version is 0.2.6 (2023-09-07). The project now publishes `keptn` 0.11.0 (2025-03-19), plus `keptn-lifecycle-operator` and `keptn-metrics-operator`. The keptn/lifecycle-toolkit repo is not archived (last push 2026-09-29).

## Evidence

`curl -sL https://charts.lifecycle.keptn.sh/index.yaml` parsed on 2026-09-30.

## Fix or workaround

None. The Keptn chapter (with its Prometheus/Jaeger/Grafana stack) was not run. The only change is that the README now installs the Conference chart from GHCR v1.1.0. Moving to the `keptn` chart would need the annotations and CRD versions in `keptntask.yaml` rechecked.

## How to verify

`make install` in `chapter-9/keptn`.

## Upstream relevance

Yes.
