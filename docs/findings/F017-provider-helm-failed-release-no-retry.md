# F017: A provider-helm Release whose first install fails stays `failed`

- **Chapter:** 6
- **Severity:** medium
- **Status:** fixed
- **Fix commit:** b2ee1fc
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`Release "conference" failed: … failed calling webhook "mcluster.cnpg.io": … connection refused` and the Release stays `STATE failed`, `READY False`.

## Root cause

The app Release installs concurrently with the CNPG operator inside the vcluster; provider-helm doesn't retry a failed release unless `rollbackLimit` is set.

## Evidence

`kubectl get releases.helm.m.crossplane.io -n team-a` and its events, 2026-09-30.

## Fix or workaround

`rollbackLimit: 3` on the app Release; it retried on the next poll (second run: ~1 minute; first run needed an annotation touch to trigger reconcile sooner).

## How to verify

Fresh Environment reaches `READY True` without manual action.

## Upstream relevance

Yes.

