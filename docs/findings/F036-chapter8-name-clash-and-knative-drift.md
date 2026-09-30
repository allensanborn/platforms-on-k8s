# F036: Knative and Argo Rollouts tutorials clash on one cluster; Knative pinned at 1.10

- **Chapter:** 8
- **Severity:** low
- **Status:** documented
- **Fix commit:** 571afcd
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

Applying `argo-rollouts/canary-release/` on a cluster that still runs the Knative `notifications-service` overwrites the Knative-owned Kubernetes Service of the same name. The Knative tutorial pins Serving `knative-v1.10.2` and Kourier `knative-v1.10.0`; the latest release is `knative-v1.23.0`.

## Root cause

Both tutorials name their Service `notifications-service`. The Knative version dates from 2023.

## Evidence

Kubernetes' `missing the kubectl.kubernetes.io/last-applied-configuration annotation` warning when applying the canary Service; `gh api repos/knative/serving/releases/latest`.

## Fix or workaround

The README says to delete the Knative Service first. Knative 1.10.2 still installs and works on Kubernetes v1.35.0 (kind v0.31.0), so it's left pinned. Upgrading is optional (drift recorded in [F031](F031-tool-version-drift.md)).

## How to verify

n/a

## Upstream relevance

Minor.
