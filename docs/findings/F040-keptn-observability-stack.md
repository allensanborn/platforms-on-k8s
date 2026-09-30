# F040: The Keptn chapter's observability install no longer completes

- **Chapter:** 9 (keptn)
- **Severity:** medium
- **Status:** open (two of three blockers fixed)
- **Fix commit:** PENDING
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`make install` in `chapter-9/keptn` on a fresh kind cluster (Kubernetes v1.35.0) failed three ways, one after another:

1. `kubectl wait --for=condition=Available deployment/cert-manager-webhook -n cert-manager --timeout=60s` → `timed out` (images still pulling). A rerun then hit `failed calling webhook "webhook.cert-manager.io"` while applying the Jaeger operator.
2. `jaeger-operator` stayed `1/2 ImagePullBackOff`: `Failed to pull image "gcr.io/kubebuilder/kube-rbac-proxy:v0.13.0": … NotFound`.
3. After fixing 2, the `Jaeger` CR in `keptn-lifecycle-toolkit-system` was never reconciled: empty status, no `jaeger` Deployment, and the operator's log stopped after `detecting orphaned deployments.` So `kubectl wait deployment/jaeger` returned `NotFound`.

## Root cause

1. A 60s timeout is too short on a fresh cluster.
2. Kubebuilder's `gcr.io/kubebuilder/kube-rbac-proxy` images were removed from gcr.io. `jaeger-operator` v1.45.0 (2023) still references them.
3. Not diagnosed. `jaeger-operator` v1.45.0 on Kubernetes 1.35 with an `olm.targetNamespaces`-based `WATCH_NAMESPACE` is the suspect. Jaeger v1 and its operator have since been superseded by Jaeger v2 on the OpenTelemetry Collector (not verified here).

## Evidence

Cluster `pek-ch9`, 2026-09-30. Logs of the four `make install` attempts were kept locally under the clone's `.scratch/keptn-install*.log`.

## Fix or workaround

`support/observability/Makefile`:
- The cert-manager wait is now `kubectl wait --for=condition=Available deployment --all -n cert-manager --timeout=300s`.
- After applying the Jaeger operator, `kubectl set image deployment/jaeger-operator -n observability kube-rbac-proxy=quay.io/brancz/kube-rbac-proxy:v0.13.0`. The operator then became Available.

Open:
- The Jaeger CR still isn't reconciled.
- The `klt` chart itself ([F038](F038-keptn-klt-chart-renamed.md)) and the rest of the chapter were not reached.

A real fix probably replaces the Jaeger operator with a plain Jaeger all-in-one Deployment (or Jaeger v2), and moves from `klt` 0.2.6 to the `keptn` chart.

## How to verify

`cd chapter-9/keptn && make install` on a fresh kind cluster.

## Upstream relevance

Yes.
