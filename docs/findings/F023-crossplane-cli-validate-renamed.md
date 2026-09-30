# F023: `crossplane beta validate` is now `crossplane resource validate`; CLI moved to cli.crossplane.io

- **Chapter:** 5
- **Severity:** info
- **Status:** documented
- **Fix commit:** —
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`crossplane: error: unexpected argument beta` with CLI v2.5.0. `releases.crossplane.io/stable/v2.4.2/bin/darwin_arm64/crank` returns HTML.

## Root cause

From v2.3 the CLI ships from `crossplane/cli` to `cli.crossplane.io` with binary `crossplane` (install.sh comments).

## Evidence

Commands above, 2026-09-30.

## Fix or workaround

Use `curl -sfL https://cli.crossplane.io/stable/current/bin/<os_arch>/crossplane` and `crossplane resource validate`.

## How to verify

`crossplane --help | grep validate`.

## Upstream relevance

Only if upstream documents validation.

