# F047: admin-go's `go test` failed because `flag.Parse()` ran in `init()`

- **Chapter:** 6
- **Severity:** low
- **Status:** fixed
- **Fix commit:** f03c06d
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`go test` → `flag provided but not defined: -test.testlogfile`.

## Root cause

`init()` parsed the command line before the test framework registered its flags.

## Evidence

`cd conference-admin/admin-go && go test .` before and after.

## Fix or workaround

`flag.Parse()` moved to the start of `main()`.

## How to verify

`go test -mod=mod ./...` in `conference-admin/admin-go`.

## Upstream relevance

Yes.
