# F020: `install.infrastructure=false` without per-service values fails to render

- **Chapter:** 6
- **Severity:** low
- **Status:** open
- **Fix commit:** —
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`chapter-6/team-b-dev-env.yaml` sets `installInfra: false`; the chart then references `.Values.agenda.kafka.url` etc., which don't exist in `values.yaml` → `nil pointer evaluating interface {}.kafka`.

## Root cause

`values.yaml` has no defaults for the external-infrastructure keys.

## Evidence

Pre-existing; `helm template x conference-application/helm/conference-app --set install.infrastructure=false` (not run in this session).

## Fix or workaround

None yet. Options: default empty maps in `values.yaml` plus a `required` message, or have the Environment Composition also create `Database`/`MessageBroker` XRs and pass their hosts.

## How to verify

`helm template` as above.

## Upstream relevance

Yes.

