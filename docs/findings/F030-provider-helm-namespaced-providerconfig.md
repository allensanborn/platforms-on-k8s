# F030: provider-helm v1.4.0 namespaced ProviderConfig still requires `secretRef.namespace`

- **Chapter:** 6
- **Severity:** info
- **Status:** documented
- **Fix commit:** b2ee1fc
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`kubectl explain providerconfigs.helm.m.crossplane.io.spec.credentials.secretRef` shows `namespace <string> -required-`.

## Root cause

CRD schema.

## Evidence

As above.

## Fix or workaround

Composition patches it from the XR namespace.

## How to verify

As above.

## Upstream relevance

No.

