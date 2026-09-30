# F032: Argo CD install fails with client-side apply (CRD annotation too long)

- **Chapter:** 4
- **Severity:** medium
- **Status:** fixed
- **Fix commit:** fa1df29
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml` → `The CustomResourceDefinition "applicationsets.argoproj.io" is invalid: metadata.annotations: Too long: may not be more than 262144 bytes`.

## Root cause

Client-side apply stores the whole object in the `last-applied-configuration` annotation; the ApplicationSet CRD in Argo CD `stable` (v3.5.3 on 2026-09-30) is larger than the annotation limit.

## Evidence

Command above on cluster `pek-m1`. With `--server-side`, all Argo CD deployments became Available (`argocd-server` image `quay.io/argoproj/argocd:v3.5.3`).

## Fix or workaround

README uses `kubectl apply -n argocd --server-side --force-conflicts -f …/stable/manifests/install.yaml`, which Argo CD's own docs now use.

## How to verify

`kubectl wait -n argocd deploy --all --for=condition=Available --timeout=400s`.

## Upstream relevance

Yes.
