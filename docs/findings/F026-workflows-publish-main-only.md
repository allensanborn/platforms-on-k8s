# F026: GitHub workflows publish to salaboy's Docker Hub, but only on `main`

- **Chapter:** n/a
- **Severity:** info
- **Status:** documented
- **Fix commit:** —
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`*-service-pipeline.yaml` jobs log in with `secrets.DOCKERHUB_USERNAME/TOKEN` and publish.

## Root cause

Upstream CI.

## Evidence

All publishing workflows trigger on `push: branches: ['main']`; the API-conformance workflows run on any push but don't publish. `gh run list` on the fork shows no runs (Actions on forks are off until enabled).

## Fix or workaround

No change needed; branch pushes can't publish. Leave the fork's `main` alone.

## How to verify

`grep -A3 '^on:' .github/workflows/*`.

## Upstream relevance

No.

