# Deployment frequency, rollout traces and post-deployment tasks (formerly: Keptn Lifecycle Toolkit)

---
_🌍 Available in_: [English](README.md) | [中文 (Chinese)](README-zh.md) | [日本語 (Japanese)](README-ja.md)| [Español](README-es.md)

> **Note:** Brought to you by the fantastic cloud-native community's [ 🌟 contributors](https://github.com/salaboy/platforms-on-k8s/graphs/contributors)!

---

> [!Important]
> **Why Keptn was replaced (September 2026).** Section 9.3 of the book uses the Keptn Lifecycle Toolkit. Keptn's maintainers asked the CNCF to archive the project because its main sponsor had stepped back and most maintainers were inactive. The CNCF TOC voted to archive it, and archiving was completed on 2025-09-08 ([cncf/toc#1584](https://github.com/cncf/toc/issues/1584)). The last release is Keptn v2.5.0 (Helm chart `keptn` 0.11.0), from 2025-03-19. The `klt` chart that this tutorial used to install stopped at 0.2.6 in 2023, and the Jaeger operator it used no longer reconciles a Jaeger instance ([F038](../../docs/findings/F038-keptn-klt-chart-renamed.md), [F040](../../docs/findings/F040-keptn-observability-stack.md)).
>
> This tutorial now shows the same ideas with tools the book already uses: [Argo CD](https://argo-cd.readthedocs.io) (chapter 4), [Argo Rollouts](https://argoproj.github.io/rollouts/) (chapter 8), Prometheus and Grafana, and [Jaeger v2](https://www.jaegertracing.io). The mapping table below shows where each Keptn step went. See [F060](../../docs/findings/F060-keptn-archived-tutorial-replaced.md) for details.

In this tutorial we measure our deliveries, watch rollouts happen, and gate them on checks. We do this without changing the application's code:

1. **Deployment frequency and duration**: every successful Argo CD sync of the Conference application is a deployment. Argo CD counts them (`argocd_app_sync_total`) and times them (`argocd_app_sync_duration_seconds_total`). Prometheus scrapes these metrics and Grafana charts them.
2. **Rollout traces**: Argo CD's application controller exports a trace of each sync over OTLP to Jaeger. This one needs Argo CD 3.6, currently a release candidate (see [Installation](#installation)).
3. **Post-deployment tasks**: an Argo CD `PostSync` hook runs a Kubernetes Job after every new version is deployed and healthy.
4. **Gates**: an Argo Rollouts `AnalysisTemplate` checks a Prometheus query during a canary release. If the check fails, the release is aborted.

## What changed from the book

| Book / Keptn tutorial | Now |
| --- | --- |
| `make install`: cert-manager, jaeger-operator, kube-prometheus manifests, OpenTelemetry Collector, `klt` Helm chart | `make install`: CloudNativePG + Strimzi operators, kube-prometheus-stack, Jaeger v2 all-in-one, Argo CD (with `otlp.address` set), Argo Rollouts |
| `kubectl annotate ns default keptn.sh/lifecycle-toolkit="enabled"` | `kubectl apply -f argocd/application.yaml`: Argo CD manages the Conference application |
| `app.kubernetes.io/name` / `part-of` / `version` labels tell Keptn what a workload is | The Argo CD `Application` is the unit of deployment. The same labels are still on the Deployments, and the post-sync task prints them |
| `KeptnTaskDefinition` `stdout-notification` (Deno) + `keptn.sh/post-deployment-tasks` label | [`hooks/post-sync-notification.yaml`](hooks/post-sync-notification.yaml): a Job annotated `argocd.argoproj.io/hook: PostSync` |
| `helm install conference …` | Argo CD syncs the chart `oci://ghcr.io/allensanborn/conference-app` `v1.1.0` |
| `kubectl edit deploy conference-notifications-service-deployment` to `v1.1.0` | Change the Application's chart version to `v1.2.0`. Argo CD syncs the new release |
| Grafana → Dashboards → *Keptn Applications* (deployment count, time between deployments, per-version duration) | Grafana → Dashboards → *Deployment frequency (Argo CD)* (deployment count, average and per-deployment duration, failures) |
| Jaeger: `lifecycle-operator` traces of the rollout | Jaeger: `argocd-controller` traces (`controller.SyncAppState`, `sync.Sync`, `sync.apply`, …) |
| `kubectl get jobs` / `kubectl logs` of `post-stdout-notification-*` | `kubectl get jobs` / `kubectl logs` of `post-sync-notification-*` |
| Keptn Evaluations (mentioned, not demonstrated) | [`gates/`](gates/): an Argo Rollouts canary with a Prometheus memory check that promotes or aborts |

Lead time for changes needs the commit time of each change, which Argo CD's metrics don't carry. The [CloudEvents/CDEvents tutorial](../dora-cloudevents/README.md) in this chapter covers that.

## Installation

Create a KinD cluster. One node is enough:

```shell
kind create cluster --name dev
```

Install everything the tutorial needs. This takes a few minutes:

```shell
make install
```

> [!Warning]
> The Makefile installs Argo CD **`v3.6.0-rc1`, a release candidate**. It is the only way to get rollout traces today. Before 3.6, Argo CD's application controller sends no spans for a sync: they were added in [argoproj/argo-cd#28396](https://github.com/argoproj/argo-cd/pull/28396), after the 3.5 branch was cut, and v3.5.3 is the latest stable release as of September 2026.
>
> Only the **rollout traces** demo needs 3.6. The deployment-frequency dashboard, the post-deployment task and the release gate work the same on the stable release: `make install ARGOCD_VERSION=v3.5.3`. With 3.5, Jaeger shows only `argocd-server` and `argocd-repo-server` spans. Once 3.6.0 is released, use `make install ARGOCD_VERSION=v3.6.0` ([F063](../../docs/findings/F063-argocd-release-candidate-pin.md)).

## Deploying the Conference application with Argo CD

[`argocd/application.yaml`](argocd/application.yaml) defines an Argo CD `Application` with two sources:

- the Conference Helm chart from GitHub Container Registry, version `v1.1.0`, with the Ingress disabled. There is no ingress controller in this cluster, and an Ingress without one never becomes Healthy. Argo CD only runs `PostSync` hooks once everything is Healthy.
- the [`hooks/`](hooks/) directory of this repository, which holds the post-deployment task. If you forked the repository, point `repoURL` and `targetRevision` at your fork and branch.

```shell
kubectl apply -f argocd/application.yaml
```

Argo CD syncs the application automatically. Wait until it is `Synced` and `Healthy`. Kafka and PostgreSQL take a few minutes:

```shell
kubectl get application conference -n argocd -w
```

```shell
NAME         SYNC STATUS   HEALTH STATUS
conference   Synced        Healthy
```

## The post-deployment task

The task is a plain Kubernetes Job with one annotation:

```yaml
metadata:
  generateName: post-sync-notification-
  annotations:
    argocd.argoproj.io/hook: PostSync
```

Argo CD creates this Job after every successful sync, once all the synced resources are Healthy. The sync operation only finishes when the Job completes. A failed hook fails the sync, which shows up in the *Failed deployments* panel. As with KeptnTaskDefinitions, platform teams can keep a library of these hooks and add them to any application's sources. This task only prints what was deployed. In practice, this is where you notify another system, run smoke or load tests, or check that the new version works:

```shell
kubectl get jobs
```

```shell
NAME                                   STATUS     COMPLETIONS   DURATION   AGE
post-sync-notification-...             Complete   1/1           4s         1m
```

```shell
kubectl logs job/<the job name from above>
```

```shell
conference-agenda-service-deployment          version=v1.0.0   image=salaboy/agenda-service-...:v1.0.0
conference-c4p-service-deployment             version=v1.0.0   image=salaboy/c4p-service-...:v1.0.0
conference-frontend-deployment                version=v1.0.0   image=salaboy/frontend-go-...:v1.0.0
conference-notifications-service-deployment   version=v1.0.0   image=salaboy/notifications-service-...:v1.0.0
conference-redis                              version=         image=docker.io/valkey/valkey:...
```

## Dashboards and traces

In separate terminals:

```shell
make port-forward-grafana
```

Open [http://localhost:3000](http://localhost:3000) (`admin`/`admin`) and go to `Dashboards` → `Deployment frequency (Argo CD)`. You should see one deployment of `conference` and how long it took. That time runs from the start of the sync until the post-deployment task finished, so it includes waiting for Kafka and PostgreSQL.

```shell
make port-forward-jaeger
```

Open [http://localhost:16686](http://localhost:16686) (this needs Argo CD 3.6, see [Installation](#installation)), pick the `argocd-controller` service and find the `controller.SyncAppState` trace. Its spans show the steps of the sync: computing the tasks, applying resources, running the `PostSync` hook.

## Releasing a new version

Now release a new version of the application. In a GitOps setup you would change the version in Git. Here we patch the Application's chart version from `v1.1.0` to `v1.2.0`:

```shell
kubectl patch application conference -n argocd --type json \
  -p '[{"op":"replace","path":"/spec/sources/0/targetRevision","value":"v1.2.0"}]'
```

Argo CD syncs the new release and runs the post-deployment task again. Once the application is `Synced` and `Healthy` again, check:

- `kubectl get jobs`: a second `post-sync-notification-*` Job. Its log shows the new version (`v1.2.0`) and images.
- Grafana: two deployments. The *Successful deployments over time* panel shows when each one happened (the time between deployments), and *Duration of each deployment* shows how long each took. The second deployment is usually much faster, because the infrastructure is already running.
- Jaeger: a second `controller.SyncAppState` trace for the new sync.

## Gating a release on a check

Keptn Evaluations let you block a release that, for example, uses too much memory. Argo Rollouts does this with an `AnalysisTemplate` that runs during a release (see [chapter 8](../../chapter-8/argo-rollouts/README.md) for Argo Rollouts itself). [`gates/analysis-template.yaml`](gates/analysis-template.yaml) queries Prometheus for the memory used by the canary pods. It fails if any pod uses more than `max-memory-mib`. [`gates/rollout.yaml`](gates/rollout.yaml) is chapter 8's notifications-service canary with an analysis step between 50% and 100%:

```shell
kubectl apply -f gates/
kubectl argo rollouts get rollout notifications-service-canary
```

Release a new version. The analysis runs three measurements, 20 seconds apart, and then the rollout is promoted:

```shell
kubectl argo rollouts set image notifications-service-canary \
  notifications-service=ghcr.io/allensanborn/notifications-service-0e27884e01429ab7e350cb5dff61b525:v1.3.0
kubectl argo rollouts get rollout notifications-service-canary --watch
```

```shell
kubectl get analysisrun
NAME                                          STATUS
notifications-service-canary-...-2-1          Successful
```

Now make the check impossible to pass (1 MiB) and release again. The analysis fails, the rollout is aborted, and the stable version keeps serving:

```shell
kubectl patch rollout notifications-service-canary --type json \
  -p '[{"op":"replace","path":"/spec/strategy/canary/steps/1/analysis/args/0/value","value":"1"}]'
kubectl argo rollouts set image notifications-service-canary \
  notifications-service=ghcr.io/allensanborn/notifications-service-0e27884e01429ab7e350cb5dff61b525:v1.2.0
kubectl argo rollouts get rollout notifications-service-canary --watch
```

```shell
Status:          ✖ Degraded
Message:         RolloutAborted: Rollout aborted update to revision 3: Metric "memory" assessed Failed due to failed (1) > failureLimit (0)
```

## Next steps

Everything here is standard Argo tooling, so it applies to any application Argo CD manages. You can go further with:

- [Argo CD Notifications](https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/), to send deployment events to Slack, webhooks or CloudEvents-consuming services such as the one in the [CloudEvents tutorial](../dora-cloudevents/README.md).
- `PreSync` hooks, for checks that must pass before a new version is deployed.
- Argo Rollouts analysis based on your own service metrics (error rate, latency) rather than memory.

## Clean up

```shell
kind delete clusters dev
```
