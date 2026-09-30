# F016: Deleting an Environment hangs on the in-vcluster Releases' finalizers

- **Chapter:** 6
- **Severity:** high
- **Status:** fixed
- **Fix commit:** b2ee1fc
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

After `kubectl delete environment`, `team-a-dev-env-cnpg` and `-conference` Releases stay with `finalizer.managedresource.crossplane.io`: `cannot get credentials secret: Secret "vc-team-a-dev-env" not found`.

## Root cause

Composed resources are deleted without ordering; the vcluster Release (and its kubeconfig Secret) went first, so the inner Releases could never connect to uninstall.

## Evidence

`kubectl get releases.helm.m.crossplane.io -n team-a -o jsonpath='{..finalizers}'` after deletion.

## Fix or workaround

Inner Releases use `managementPolicies: ["Observe", "Create", "Update", "LateInitialize"]` (no Delete): deleting the vcluster deletes everything inside it. Second full cycle: all Releases, the ProviderConfig and pods gone within ~2 minutes. (Crossplane `Usage` ordering would be the alternative.)

## How to verify

Create then delete `chapter-6/team-a-dev-env.yaml`; `kubectl get releases.helm.m.crossplane.io,providerconfigs.helm.m.crossplane.io -n team-a` → none.

## Upstream relevance

Yes.

