# F021: Admin UI still writes the Crossplane v1 `Environment` shape

- **Chapter:** 6
- **Severity:** medium
- **Status:** open
- **Fix commit:** —
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`conference-admin/admin-go/api/types/v1alpha1/environment.go` has `spec.compositionSelector` at the root and `writeConnectionSecretToRef`; no namespace handling for a namespaced XR.

## Root cause

Written for v1 claims.

## Evidence

Source read 2026-09-30; not run.

## Fix or workaround

None. Needs Go changes and a rebuilt/published image (publishing not authorized). README carries a warning.

## How to verify

n/a

## Upstream relevance

Yes.

