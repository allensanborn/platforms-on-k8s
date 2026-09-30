# F046: Chapter 8 release demos need two image versions; the fork publishes v1.2.0 and v1.3.0

- **Chapter:** 8, 9 (keptn)
- **Severity:** low
- **Status:** documented
- **Fix commit:** f03c06d, cdf1e79
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

Chapter 8 switches `notifications-service` and `frontend` from `v1.0.0` to `v1.1.0` and shows `/service/info` answering `1.0.0` or `1.1.0`. In the book, the frontend's `v1.1.0` also has a different color theme.

## Root cause

The book's `v1.1.0` images come from upstream branch `v1.1.0`. `/service/info` reported `getEnv("VERSION", "1.0.0")`, so the version was fixed in the code.

## Evidence

Upstream branches listed in [F043](F043-upstream-v3-chart.md).

## Fix or workaround

The services now take their default version from `var buildVersion`, set at build time with `-ldflags -X main.buildVersion=<tag>` (injection checked by building with `9.9.9` and finding the string in the binary). The fork publishes `frontend-go` and `notifications-service` as `v1.2.0` and `v1.3.0`, built from the same main-line source, so they differ only in the reported version. Chapter-8 READMEs use `v1.2.0` → `v1.3.0` and say the color theme no longer changes. Rebuilding `v1.3.0` from upstream branch `v1.1.0` plus this fork's fixes would restore the theme (not done).

## How to verify

`curl …/service/info` returns `"version":"1.2.0"` or `"1.3.0"`.

## Upstream relevance

Minor.
