# F013: Crossplane needs aggregated RBAC for composed operator resources

- **Chapter:** 5
- **Severity:** medium
- **Status:** fixed
- **Fix commit:** 7d71eb2
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

Without it, composing `postgresql.cnpg.io` or `kafka.strimzi.io` resources is forbidden to Crossplane's service account.

## Root cause

v2 composes arbitrary resources, but its ClusterRole only covers provider CRDs, XRs and some core types.

## Evidence

Crossplane docs (`composition` pages, CNPG example). With the ClusterRole in place, all compositions reconciled.

## Fix or workaround

`chapter-5/crossplane/aggregate-to-crossplane.yaml` with label `rbac.crossplane.io/aggregate-to-crossplane: "true"` for CNPG clusters, Strimzi kafkas/kafkanodepools/kafkatopics, services, deployments. Whether services/deployments are already covered by default was not tested.

## How to verify

Apply the XRs; `kubectl get dbs,mbs -n team-a` `SYNCED True`.

## Upstream relevance

Yes.

