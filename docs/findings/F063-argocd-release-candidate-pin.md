# F063: The Keptn-replacement tutorial pins an Argo CD release candidate (v3.6.0-rc1)

- **Chapter:** 9 (keptn)
- **Severity:** low
- **Status:** open (bump to GA when v3.6.0 ships)
- **Fix commit:** —
- **Found:** 2026-09-30, branch `keptn-current`

## Symptom

`chapter-9/keptn/Makefile` has `ARGOCD_VERSION ?= v3.6.0-rc1`, a pre-release.

## Root cause

Sync traces need Argo CD 3.6 ([F062](F062-argocd-sync-traces-need-3-6.md)). As of 2026-09-30 the latest GA release is v3.5.3 (2026-09-14), and v3.6.0-rc1 came out on 2026-09-16 (`gh api repos/argoproj/argo-cd/releases`).

Only the rollout-traces demo depends on 3.6. The deployment-frequency dashboard (`argocd_app_sync_total` has the same `phase`/`dry_run` labels in v3.5.3), the PostSync hook and the Argo Rollouts gate don't. The README says so and gives `make install ARGOCD_VERSION=v3.5.3` as the stable option.

## Fix or workaround

When `v3.6.0` is released:

1. `gh api repos/argoproj/argo-cd/releases/latest --jq .tag_name` shows `v3.6.0` (or later 3.6.x).
2. In `chapter-9/keptn/Makefile`, set `ARGOCD_VERSION ?= v3.6.0` and shorten the comment above it.
3. In `chapter-9/keptn/README.md` (Installation), replace the release-candidate warning with one sentence: Argo CD 3.6 or later is needed for the trace demo.
4. Rerun the tutorial and check that Jaeger's `argocd-controller` service still has `controller.SyncAppState` traces. Also check that `otlp.address` is still wired to `ARGOCD_APPLICATION_CONTROLLER_OTLP_ADDRESS` in the release's `manifests/install.yaml`.
5. Mark this finding fixed.

## How to verify

`grep ARGOCD_VERSION chapter-9/keptn/Makefile` shows a GA tag.

## Upstream relevance

Yes.
