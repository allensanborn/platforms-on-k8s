# F011: Strimzi keeps Kafka PVCs unless `deleteClaim: true`

- **Chapter:** 2, 5
- **Severity:** low
- **Status:** fixed
- **Fix commit:** 27da304
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

After uninstalling, `data-0-<cluster>-<pool>-0` stays; reinstalling reuses old data.

## Root cause

Strimzi's `persistent-claim` storage defaults to `deleteClaim: false`.

## Evidence

Chapter-5 XR deletion: with `deleteClaim: true` the Kafka PVC was gone within seconds; CNPG's PVC (owned by the Cluster) was removed too.

## Fix or workaround

`deleteClaim: true` in the chart and in the MessageBroker Composition. Valkey's PVC is still kept by `helm uninstall` (README says to delete `conference-redis`).

## How to verify

`kubectl delete -f chapter-5/my-messagebroker-kafka.yaml`, then `kubectl get pvc -n team-a`.

## Upstream relevance

Yes.

