# F012: Chapter 5/6 Compositions and XRDs don't apply on Crossplane v2

- **Chapter:** 5, 6
- **Severity:** high
- **Status:** fixed
- **Fix commit:** 7d71eb2, b2ee1fc
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

Crossplane v2 rejects/ignores `spec.resources` Compositions (native patch-and-transform removed), `writeConnectionSecretsToNamespace`, claims on v2 XRDs, and `spec.compositionSelector` at the XR root.

## Root cause

Crossplane v2 changes (see the v2 upgrade guide): XRD `apiextensions.crossplane.io/v2` with `scope` (default Namespaced), `mode: Pipeline` with functions, Crossplane fields under `spec.crossplane`, no XR connection secrets.

## Evidence

Tested with Crossplane v2.4.2 on kind, 2026-09-30.

## Fix or workaround

XRDs → v2 `scope: Namespaced`; Compositions → `mode: Pipeline` + `function-patch-and-transform` v0.11.0; XRs in `team-a` with `spec.crossplane.compositionSelector`; local resources composed directly (Valkey Deployment+Service, CNPG Cluster, Strimzi resources) instead of provider-helm + Bitnami.

## How to verify

`kubectl get dbs,mbs -n team-a` all `READY True`; app e2e passes with `chapter-5/app-values.yaml`.

## Upstream relevance

High.

