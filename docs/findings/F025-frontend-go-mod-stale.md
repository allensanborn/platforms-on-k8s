# F025: frontend-go's go.mod needs `go mod tidy` before it builds

- **Chapter:** dev loop
- **Severity:** low
- **Status:** fixed
- **Fix commit:** 3256cfc
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`go vet .` / `go test` → `go: updates to go.mod needed; to update it: go mod tidy`.

## Root cause

Dependencies require a newer `go` directive than `go 1.19`.

## Evidence

Reproduced on the unmodified file (stash test), Go toolchain on this Mac, 2026-09-30.

## Fix or workaround

`go` directive moved to 1.21 (the only change `-mod=mod` made). Other services not checked.

## How to verify

`cd conference-application/frontend-go && go vet .`

## Upstream relevance

Yes.

