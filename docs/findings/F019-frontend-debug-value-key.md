# F019: The Conference chart's frontend debug value is `services.frontend.debug`

- **Chapter:** 6
- **Severity:** low
- **Status:** documented
- **Fix commit:** b2ee1fc
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

The wiki's v2 edition page patched `frontend.debugEnabled` (marked unverified).

## Root cause

Key is defined in `templates/frontend.yaml` (`.Values.services.frontend.debug` → `FEATURE_DEBUG_ENABLED`).

## Evidence

`curl http://localhost:8080/api/features/` inside the environment → `{"DebugEnabled":"true",…}`.

## Fix or workaround

Composition patches `spec.forProvider.values.services.frontend.debug` (as the book did).

## How to verify

As in Evidence.

## Upstream relevance

No (the repo was right; the wiki page was wrong).

