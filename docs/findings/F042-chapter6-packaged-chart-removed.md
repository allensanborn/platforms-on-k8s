# F042: Removed the packaged chart copy from chapter 6

- **Chapter:** 6
- **Severity:** info
- **Status:** documented (decision)
- **Fix commit:** cdf1e79
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`chapter-6/charts/conference-app-v1.1.0.tgz` was committed so the Environment Composition could load the chart from raw.githubusercontent.com while the GHCR package was private.

## Root cause

It was a stopgap until the GHCR package was public.

## Evidence

Once public, the Composition pulled `oci://ghcr.io/allensanborn/conference-app` from a cluster with no registry credentials, and the chapter-6 test passed ([F002](F002-published-chart-embeds-bitnami.md)).

## Fix or workaround

Removed. Nothing references it: the Composition and README use `repository: oci://ghcr.io/allensanborn` with the chart version, now `v1.2.0`. A binary copy would go stale with every chart release, and GHCR is the one source.

## How to verify

`git grep chapter-6/charts` returns nothing.

## Upstream relevance

No.
