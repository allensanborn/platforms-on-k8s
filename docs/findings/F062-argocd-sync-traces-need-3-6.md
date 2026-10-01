# F062: Argo CD only exports sync traces from 3.6; the tutorial pins v3.6.0-rc1

- **Chapter:** 9 (keptn)
- **Severity:** medium
- **Status:** documented (tested)
- **Fix commit:** see branch `keptn-current`
- **Found:** 2026-09-30, branch `keptn-current`

## Symptom

On Argo CD v3.5.3 (the newest GA release, 2026-09-14), with `otlp.address` set, Jaeger only receives `repository.RepoServerService/GenerateManifest` spans (from `argocd-controller` and `argocd-repo-server`) and `grpc.health.v1.Health/Check`. There are no spans for a sync, which is what replaces the book's Keptn lifecycle-operator trace. Measured on kind on 2026-10-01 after switching the tutorial's cluster to v3.5.3. On the same cluster, the PostSync hook and `argocd_app_sync_total` / `argocd_app_sync_duration_seconds_total` worked unchanged.

## Root cause

The application controller and the gitops-engine sync code got spans (`controller.SyncAppState`, `sync.Sync`, `sync.getSyncTasks`, `sync.apply`, `sync.runTasks`, …) in [argoproj/argo-cd#28396](https://github.com/argoproj/argo-cd/pull/28396), merged 2026-07-13. `controller/sync.go` at `v3.5.3` imports no OpenTelemetry package, and at `v3.6.0-rc1` it calls `tracer.Start(ctx, "controller.SyncAppState")`. The v3.6.0-rc1 `install.yaml` also wires `ARGOCD_APPLICATION_CONTROLLER_OTLP_ADDRESS` from `argocd-cmd-params-cm`'s `otlp.address`; v3.5.3 doesn't.

## Fix or workaround

`chapter-9/keptn/Makefile` pins `ARGOCD_VERSION ?= v3.6.0-rc1`. Move it to `v3.6.0` when that is released.

## How to verify

Run `make install`, then `kubectl apply -f argocd/application.yaml`. In Jaeger, the service `argocd-controller` then has `controller.SyncAppState` traces.

## Upstream relevance

Yes, for anyone wiring Argo CD tracing.
