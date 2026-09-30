# F010: `helm dependency build` fails for the Valkey dependency unless its repo is added

- **Chapter:** 2
- **Severity:** low
- **Status:** documented
- **Fix commit:** 7d71eb2
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`Error: no repository definition for https://valkey.io/valkey-helm/. Please add the missing repos via 'helm repo add'`.

## Root cause

`build` resolves repositories from the local repo list; `update` fetches them directly.

## Evidence

Fresh `HELM_*_HOME`, 2026-09-30.

## Fix or workaround

READMEs use `helm dependency update`, or the published chart.

## How to verify

`helm dependency update conference-application/helm/conference-app`.

## Upstream relevance

Yes.

