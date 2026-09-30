# F048: Compiled binaries are committed in the repo

- **Chapter:** 6, dev loop
- **Severity:** info
- **Status:** documented
- **Fix commit:** —
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`conference-admin/admin-go/admin` and `conference-application/c4p-service/c4p-service` are tracked executables.

## Root cause

Local build outputs were committed upstream (`cfc4d1a adding admin ui and helm chart`).

## Evidence

`git ls-files conference-admin/admin-go/admin conference-application/c4p-service/c4p-service`.

## Fix or workaround

Left as they are. They aren't used by any image or manifest, but they show up in `git grep`.

## How to verify

n/a

## Upstream relevance

Yes: delete them and add them to `.gitignore`.
