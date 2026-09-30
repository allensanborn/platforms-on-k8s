# F035: Argo Rollouts install fails with client-side apply (CRD annotation too long)

- **Chapter:** 8
- **Severity:** medium
- **Status:** fixed
- **Fix commit:** PENDING
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`CustomResourceDefinition.apiextensions.k8s.io "analysisruns.argoproj.io" is invalid: metadata.annotations: Too long` (same for `rollouts.argoproj.io`). The controller starts anyway, but `kubectl apply -f canary-release/` fails with `no matches for kind "Rollout"`.

## Root cause

Same as [F032](F032-argocd-client-side-apply-too-long.md): the CRDs of Argo Rollouts v1.10.0 (`releases/latest`) are too large for the last-applied annotation.

## Evidence

Command in the README, cluster `pek-ch8`.

## Fix or workaround

`kubectl apply --server-side -n argo-rollouts -f …/install.yaml`. The README also uses `releases/latest`, which now resolves to v1.10.0 (the plugin tested was also v1.10.0).

## How to verify

`kubectl get crd rollouts.argoproj.io`.

## Upstream relevance

Yes.
