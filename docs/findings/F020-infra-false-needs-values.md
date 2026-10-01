# F020: `install.infrastructure=false` without per-service values fails to render

- **Chapter:** 6
- **Severity:** low
- **Status:** fixed (clear error); chapter 6 `installInfra: false` still has no hosts to use
- **Fix commit:** PENDING (chart v1.2.0)
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`chapter-6/team-b-dev-env.yaml` sets `installInfra: false`; the chart then references `.Values.agenda.kafka.url` etc., which don't exist in `values.yaml` → `nil pointer evaluating interface {}.kafka`.

## Root cause

`values.yaml` has no defaults for the external-infrastructure keys.

## Evidence

Pre-existing; `helm template x conference-application/helm/conference-app --set install.infrastructure=false` (not run in this session).

## Fix or workaround

Chart v1.2.0:
- `values.yaml` now has empty defaults for every external-infrastructure key.
- The templates use `required`, so `helm template x conference-application/helm/conference-app --set install.infrastructure=false` now fails with `notifications.kafka.url is required when install.infrastructure=false` instead of a nil-pointer error.

`chapter-6/team-b-dev-env.yaml` (`installInfra: false`) still can't produce a working app, because the Environment Composition has no hosts to pass. Making it work means composing `Database`/`MessageBroker` XRs next to the vcluster, and that is not done.

## How to verify

`helm template` as above.

## Upstream relevance

Yes.

