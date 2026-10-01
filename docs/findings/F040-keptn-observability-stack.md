# F040: The Keptn chapter's observability install no longer completes

- **Chapter:** 9 (keptn)
- **Severity:** medium
- **Status:** superseded by F060 (keptn-current). Keptn is archived by the CNCF (cncf/toc#1584) and chapter 9.3 is replaced on branch `keptn-current`
- **Fix commit:** 47641bd
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`make install` in `chapter-9/keptn` on a fresh kind cluster (Kubernetes v1.35.0) failed three ways, one after another:

1. `kubectl wait --for=condition=Available deployment/cert-manager-webhook -n cert-manager --timeout=60s` → `timed out` (images still pulling). A rerun then hit `failed calling webhook "webhook.cert-manager.io"` while applying the Jaeger operator.
2. `jaeger-operator` stayed `1/2 ImagePullBackOff`: `Failed to pull image "gcr.io/kubebuilder/kube-rbac-proxy:v0.13.0": … NotFound`.
3. After fixing 2, the `Jaeger` CR in `keptn-lifecycle-toolkit-system` was never reconciled: empty status, no `jaeger` Deployment, and the operator's log stopped after `detecting orphaned deployments.` So `kubectl wait deployment/jaeger` returned `NotFound`.

## Root cause

1. A 60s timeout is too short on a fresh cluster.
2. Kubebuilder's `gcr.io/kubebuilder/kube-rbac-proxy` images were removed from gcr.io. `jaeger-operator` v1.45.0 (2023) still references them.
3. Not diagnosed. `jaeger-operator` v1.45.0 on Kubernetes 1.35 with an `olm.targetNamespaces`-based `WATCH_NAMESPACE` is the suspect.
4. (Second run, after replacing Jaeger) `helm upgrade --install keptn klt/klt --wait` → `context deadline exceeded`. `certificate-operator` stayed 0/1 with 7 restarts, while `lifecycle-operator` and `metrics-operator` crash-looped logging `waiting for certificate secret to be available.` Not diagnosed. The host was heavily loaded by another, unrelated kind cluster (about 480% CPU), and probes everywhere were timing out, so this is not conclusive.

## Evidence

Cluster `pek-ch9`, 2026-09-30. Logs of the four `make install` attempts were kept locally under the clone's `.scratch/keptn-install*.log`.

## Fix or workaround

`support/observability/Makefile`:
- The cert-manager wait is now `kubectl wait --for=condition=Available deployment --all -n cert-manager --timeout=300s`.
- After applying the Jaeger operator, `kubectl set image deployment/jaeger-operator -n observability kube-rbac-proxy=quay.io/brancz/kube-rbac-proxy:v0.13.0`. The operator then became Available.

- The Jaeger operator and Jaeger CR are replaced by a Jaeger all-in-one `Deployment` (`jaegertracing/all-in-one:1.74.0`) with the same `jaeger-collector`/`jaeger-query` Services (`config/jaeger.yaml`). After that, Jaeger, the OTel collector and the Prometheus/Grafana stack all came up and `make install-observability` succeeded.

Open:
- The `klt` chart itself ([F038](F038-keptn-klt-chart-renamed.md)) and the rest of the chapter were not reached.

A real fix probably replaces the Jaeger operator with a plain Jaeger all-in-one Deployment (or Jaeger v2), and moves from `klt` 0.2.6 to the `keptn` chart.

## How to verify

`cd chapter-9/keptn && make install` on a fresh kind cluster.

## Upstream relevance

Yes.
