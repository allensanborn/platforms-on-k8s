# F003: Vendored subchart tarballs didn't match Chart.yaml

- **Chapter:** 2
- **Severity:** low
- **Status:** fixed
- **Fix commit:** 27da304
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`charts/postgresql-12.5.7.tgz` was checked in while `Chart.yaml` asked for 12.5.9; there was no `Chart.lock`. The chart's own `.gitignore` ignores `*.tgz`, so the tarballs had been force-added.

## Root cause

Dependencies vendored by hand and not refreshed.

## Evidence

`git ls-files conference-application/helm/conference-app/charts` listed `kafka-22.1.5.tgz`, `postgresql-12.5.7.tgz`, `redis-17.11.3.tgz`.

## Fix or workaround

Tarballs removed; `Chart.lock` generated for valkey 0.12.0. Users run `helm dependency update` (see [F010](F010-helm-dependency-build-needs-repo.md)) or install the published chart.

## How to verify

`helm dependency update conference-application/helm/conference-app && helm lint conference-application/helm/conference-app`.

## Upstream relevance

Yes, minor.

