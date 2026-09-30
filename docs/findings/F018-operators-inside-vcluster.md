# F018: The operator-based chart needs CNPG and Strimzi inside each vcluster

- **Chapter:** 6
- **Severity:** medium
- **Status:** fixed
- **Fix commit:** b2ee1fc
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

With `installInfra: true`, installing the chart into a vcluster fails with `no matches for kind "Cluster" in version "postgresql.cnpg.io/v1"`.

## Root cause

Host-cluster operators don't see custom resources created inside a vcluster (vcluster doesn't sync them by default).

## Evidence

Release event: `resource mapping not found for name: "conference-postgresql" … no matches for kind "Cluster"`.

## Fix or workaround

The Composition installs `cloudnative-pg` 0.29.1 and `strimzi-kafka-operator` 1.2.0 (watchAnyNamespace) Releases inside the vcluster. Alternative left for later: `installInfra: false` + composed `Database`/`MessageBroker` on the host + vcluster host DNS fallback and secret sync.

## How to verify

Inside the vcluster, `helm list -A` shows `cnpg`, `strimzi`, `conference` deployed; e2e passes.

## Upstream relevance

Yes.

