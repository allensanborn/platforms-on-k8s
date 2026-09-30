# F027: Environment `READY` means Releases deployed, not app ready; vcluster PVC survives deletion

- **Chapter:** 6
- **Severity:** low
- **Status:** documented
- **Fix commit:** b2ee1fc
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`kubectl get env` is `READY True` while app pods in the vcluster are still starting; after deletion `data-<name>-0` (5Gi) remains, and a new Environment with the same name reuses the old vcluster state.

## Root cause

provider-helm readiness is the Helm release state; the vcluster StatefulSet's PVC isn't deleted by `helm uninstall`.

## Evidence

`kubectl get pvc -n team-a` after deletion.

## Fix or workaround

README documents both. A readiness check on the app would need an Object/observe of resources inside the vcluster.

## How to verify

As in Evidence.

## Upstream relevance

Yes.

