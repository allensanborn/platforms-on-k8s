# Update notes: Bitnami replacements and Crossplane v2

Chronological log. Each problem has its own write-up in the [findings index](docs/findings/README.md).

Branch `crossplane-v2-and-bitnami-replacements` of a fork of `salaboy/platforms-on-k8s`, started 2026-09-30.

Why: Bitnami stopped publishing versioned images to `docker.io/bitnami` in August 2025, so the book's pinned Redis, PostgreSQL and Kafka images return 404 and the pods sit in `ImagePullBackOff`. Crossplane v2 removed native patch-and-transform, cluster-scoped-by-default XRs and XR connection secrets, so the chapter 5 and 6 compositions no longer apply. Every change below was tested on a local kind cluster (kind v0.31.0, Kubernetes v1.35.0) unless marked UNTESTED.

## Progress log

- 15:29 fork + clone, branch created.
- 15:50 chapter 2 chart: PASS on kind cluster `pek-ch2` (all pods Ready, proposal submitted and approved, agenda item created, notification sent, 4 events on `events-topic`).
- 16:00 chapter 5 local compositions: PASS on fresh kind cluster `pek-ch5` (Crossplane v2.4.2; XRs Ready; app installed with `install.infrastructure=false`; same end-to-end flow).
- 16:30 chapter 6 Environment: PASS on `pek-ch5` (vcluster 0.37.2 created in `team-a`, operators + app installed inside it through the exported kubeconfig, same end-to-end flow through a port-forward into the vcluster; create/delete cycle run twice).
- 16:34 chapter 5 AWS compositions: converted, render + schema validation only (UNTESTED against AWS).
- 2026-09-30 (branch `aws-floci`) chapter 5 AWS compositions: PASS against Floci 2.1.0 on kind `pek-floci` (XRs Ready, init Jobs Complete, chart v1.1.0 e2e PASS with 0 restarts, run twice, the second time with the README commands as written; delete removed every MR and Floci's containers). Not run against a real AWS account.
- 16:37 docker-compose files and Dagger pipelines: images replaced; two compose stacks brought up locally.
- 16:40 all `pek-` clusters deleted.
- 16:44 chart v1.1.0 with `wait-for-dependencies` init containers ([F005](docs/findings/F005-services-crashloop-until-infra-ready.md)) installed from the packaged `.tgz` on fresh cluster `pek-m1`: 0 restarts, e2e PASS.
- 16:47 chart pushed to `oci://ghcr.io/allensanborn/conference-app:v1.1.0` (digest `sha256:a7e7b8e3e07fd9459bc56cc711887945ff2a2ac0d70acf0b2ccdcc39100b4246`), linked to this repo; still **private** ([F002](docs/findings/F002-published-chart-embeds-bitnami.md)). READMEs repointed.
- 16:50 frontend-go Kafka read retry ([F006](docs/findings/F006-frontend-exits-on-kafka-read-error.md)): unit test passes; local ko build loaded into kind survived a broker restart with 0 restarts (original image: 3). Not published.
- 16:53 findings log `docs/findings/` created and backfilled (F001-F031).
- 17:05 chapter 4: Argo CD v3.5.3 (needs `--server-side`, [F032](docs/findings/F032-argocd-client-side-apply-too-long.md)); staging umbrella on GHCR v1.1.0 installed with Helm and switched to debug values: PASS; Argo CD sync of `staging-kube` from this branch: Synced/Healthy, e2e PASS after F007 recurred ([F033](docs/findings/F033-argocd-staging-bitnami-values.md)). Argo CD sync of the umbrella chart is blocked until the GHCR package is public.
- 17:30 chapter 8: Knative Serving 1.10.2 + Strimzi/CNPG/Valkey infra, e2e and canary split PASS; Argo Rollouts v1.10.0 canary and blue-green PASS (F034-F036).
- 17:34 chapter 9: DORA CloudEvents demo on CNPG, metric endpoint PASS (F037); Keptn `klt` chart frozen, not run (F038); version drift table in F031.
- 17:45 chapter 7 (Dapr): branch `v2.0.0-bitnami-replacements`, chart v2.1.0, e2e PASS with Dapr 1.11.0 (F039). Not published.
- 17:50 `helm install … oci://ghcr.io/allensanborn/conference-app --version v1.1.0` pulled digest `sha256:a7e7b8e3…` and passed e2e with 0 restarts (with local registry credentials; anonymous pull needs the package to be public).
- 17:50 GHCR package made public by the owner; anonymous manifest request → 200.
- 17:52-18:15 fresh cluster `pek-final`, no registry credentials:
  - chapter 5 README flow with the GHCR chart: PASS.
  - chapter 6 Environment with the GHCR chart: PASS, 0 restarts inside the vcluster, debug flag on. The first attempt stalled 10 minutes on provider-helm's default poll; with `--poll=1m` a second Environment was Ready in 5m40s ([F017](docs/findings/F017-provider-helm-failed-release-no-retry.md)).
  - chapter 4 Argo CD sync of the umbrella chart: Synced/Healthy, e2e PASS, and the debug values switch works.
- 18:20 chapter 9 Keptn: `make install` fails on a fresh cluster. Fixed the cert-manager wait and the removed `gcr.io/kubebuilder/kube-rbac-proxy` image; the Jaeger CR is still never reconciled by jaeger-operator 1.45 ([F040](docs/findings/F040-keptn-observability-stack.md)). Chapter not completed.
- 18:25 `from-source/README.md` and the main-branch chapter-7 README repointed; translated READMEs left as-is ([F041](docs/findings/F041-translated-readmes-stale.md)). All `pek-` clusters deleted.

### Pass 3: self-contained artifacts (user authorized publishing images)

- 18:27 inventory of `salaboy/*` images ([F044](docs/findings/F044-image-inventory.md)); upstream remote present.
- 18:31-18:38 `hack/publish-ghcr.sh` built and pushed 17 multi-arch image tags to `ghcr.io/allensanborn` ([Published artifacts](#published-artifacts)). ko no longer builds single-file packages, so the chapter-9 functions were repackaged ([F045](docs/findings/F045-ko-single-file-builds.md)). A second run skipped every existing tag.
- 18:35 Admin UI on Crossplane v2 ([F021](docs/findings/F021-admin-ui-v1-environment.md)); services report a build-time version ([F046](docs/findings/F046-chapter8-demo-versions.md)).
- 18:40 everything repointed at `ghcr.io/allensanborn`: chart `conference-app` v1.2.0, `conference-admin` v1.2.0, Dapr chart v2.1.0, chapters 2, 4, 5, 6, 8, 9, compose and pipelines. `chapter-6/charts/` removed ([F042](docs/findings/F042-chapter6-packaged-chart-removed.md)). Upstream `v3.0.0` investigated ([F043](docs/findings/F043-upstream-v3-chart.md)).
- 18:50 admin API create/list/delete on Crossplane v2 PASS (temporary pull secret; images still private).
- 19:04 chart v1.2.0: clear error for `install.infrastructure=false` without values ([F020](docs/findings/F020-infra-false-needs-values.md)).
- 19:30 index annotation verified on a local registry; publish script fixed ([F049](docs/findings/F049-ghcr-package-repo-link.md)). Keptn labels removed from both charts ([F050](docs/findings/F050-keptn-labels-removed.md)).
- 19:38 packaged charts tested with a pull secret, then pushed: conference-app v1.2.0 and v2.1.0, and conference-admin v1.2.0.
- Waiting: the 12 private packages need flipping to public before the no-credentials tests.

## Chapter 2: conference-app Helm chart

| What | Before (Bitnami) | After | Tested |
| --- | --- | --- | --- |
| Redis chart | `bitnamicharts/redis` 17.11.3 | official `valkey` 0.12.0 (`https://valkey.io/valkey-helm/`), `alias: redis` | PASS |
| PostgreSQL | `bitnamicharts/postgresql` 12.5.9 | CloudNativePG `Cluster` in `templates/infrastructure.yaml`; operator chart `cloudnative-pg` 0.29.1 (operator 1.30.1) installed as a prerequisite | PASS |
| Kafka | `bitnamicharts/kafka` 22.1.5 | Strimzi `Kafka` + `KafkaNodePool` + `KafkaTopic` (`kafka.strimzi.io/v1`, KRaft, Kafka 4.3.1); operator 1.2.0 with `watchAnyNamespace=true` installed as a prerequisite | PASS |
| Vendored subcharts | `charts/{redis-17.11.3,postgresql-12.5.7,kafka-22.1.5}.tgz` checked in (postgresql tgz did not match Chart.yaml's 12.5.9) | removed; `Chart.lock` regenerated for valkey 0.12.0; run `helm dependency build` (the chart's own `.gitignore` already ignores `*.tgz`) | PASS |

### Names (release `conference`, namespace `default`)

| Consumer | Before | After |
| --- | --- | --- |
| agenda `REDIS_HOST` | `conference-redis-master` | `conference-redis` |
| agenda `REDIS_PASSWORD` | Secret `conference-redis` / key `redis-password` (chart-generated, random) | Secret `conference-redis` / key `redis-password` (created by this chart, value `redis`) |
| c4p `POSTGRES_HOST` | `conference-postgresql` | `conference-postgresql-rw` |
| c4p `POSTGRES_PASSWORD` | Secret `conference-postgresql` / key `postgres-password` | Secret `conference-postgresql-superuser` / key `password` |
| all four services `KAFKA_URL` | `conference-kafka` | `conference-kafka-bootstrap` (port 9092, plaintext) |
| Kafka pod | `conference-kafka-0` | `conference-conference-dual-role-0` (`<cluster>-<pool>-<n>`; the pool is prefixed with the release name so two releases can share a namespace) |
| PVCs | `data-conference-kafka-0`, `data-conference-postgresql-0`, `redis-data-conference-redis-master-0` | `data-0-conference-conference-dual-role-0`, `conference-postgresql-1`, `conference-redis` |
| `install.infrastructure=false` values | `*.redis.secretName` required; key fixed to `redis-password` / `postgres-password` | `agenda.redis.secretName` optional (omit for an auth-less Redis); new optional `agenda.redis.secretKey` (default `redis-password`) and `c4p.postgresql.secretKey` (default `password`) |

Why the superuser Secret and not CloudNativePG's `-app` Secret: `c4p-service.go` builds its DSN as `postgresql://<POSTGRES_USERNAME|postgres>:<pw>@host:5432/postgres`, so it needs the `postgres` user and database. CloudNativePG's `postInitSQLRefs` runs the `c4p-init-sql` ConfigMap as the superuser in the `postgres` database, which is where c4p reads. No service code changed; no images rebuilt.

### Things found while testing

- **ingress-nginx's kind manifest (`main`) no longer pins the controller to the `ingress-ready=true` node.** On the chapter's 1+3 node cluster the controller landed on a worker and `curl http://localhost` got "connection reset". Fix in the README: `kubectl patch deploy -n ingress-nginx ingress-nginx-controller -p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"}}}}}'`. (Controller image today: v1.15.1.)
- **Frontend crash-loops until Kafka is ready.** `frontend.go` panics in `isKafkaAlive` if the dial fails, and `consumeFromKafka` exits on `Not Coordinator For Group` while `__consumer_offsets` is created. It recovered on its own restart backoff in one case; in the first run it also saw `i/o timeout` to the bootstrap Service for ~5 minutes after Kafka was `Ready`, which cleared after Strimzi's NetworkPolicy was re-created (cause not pinned down; kindnet's NetworkPolicy enforcement is the suspect). README says to `rollout restart` the frontend if it stays in `CrashLoopBackOff`.
- Kafka took ~5 minutes to become `Ready` on kind (operator → broker pod → entity operator).
- `chapter-2/kind-load.sh` now pulls/loads the new images (valkey 9.1.2, CNPG operator 1.30.1 + `postgresql:18.6-system-trixie`, Strimzi operator 1.2.0 + `kafka:1.2.0-kafka-4.3.1`). The ingress-nginx images were dropped from the list because the manifest from `main` moves with upstream.
- Published chart `oci://docker.io/salaboy/conference-app:v1.0.0` still embeds the Bitnami subcharts; only its owner can republish it. The chapter-2 README now installs from the local chart path.

## Chapter 5: Crossplane v2 (local)

| What | Before (Crossplane v1) | After (Crossplane v2.4.2) | Tested |
| --- | --- | --- | --- |
| XRDs | `apiextensions.crossplane.io/v1`, cluster-scoped | `apiextensions.crossplane.io/v2`, `scope: Namespaced`; `size` gets an `enum`; printer column reads `spec.crossplane.compositionSelector` | PASS |
| Compositions | `spec.resources` (native P&T) wrapping provider-helm Releases of Bitnami charts, `writeConnectionSecretsToNamespace` | `mode: Pipeline` + `function-patch-and-transform` v0.11.0; compose resources directly: Valkey `Deployment`+`Service`, CloudNativePG `Cluster`, Strimzi `KafkaNodePool`+`Kafka`+`KafkaTopic` | PASS |
| RBAC | provider-helm had cluster-admin | `crossplane/aggregate-to-crossplane.yaml` (label `rbac.crossplane.io/aggregate-to-crossplane: "true"`) for `postgresql.cnpg.io` clusters, `kafka.strimzi.io` kafkas/kafkanodepools/kafkatopics, services, deployments | PASS |
| XR requests | `spec.compositionSelector`, no namespace (`default`) | `spec.crossplane.compositionSelector`, `namespace: team-a` | PASS |
| provider-helm | `xpkg.upbound.io/crossplane-contrib/provider-helm:v0.17.0` | `xpkg.crossplane.io/crossplane-contrib/provider-helm:v1.4.0` (only chapter 6 needs it now) | PASS (used in ch. 6) |
| PVC cleanup on XR delete | PVCs were left behind | CNPG PVC owned by the Cluster; Strimzi `deleteClaim: true`. Verified: both PVCs gone after deleting the XRs | PASS |

### Names (namespace `team-a`)

| Consumer (`app-values.yaml`) | Before | After |
| --- | --- | --- |
| XR name (keyvalue) | `my-db-keyavalue` (typo) | `my-db-keyvalue` |
| agenda `redis.host` | `my-db-keyavalue-redis-master.default.svc.cluster.local` | `my-db-keyvalue-redis.team-a.svc.cluster.local` |
| agenda `redis.secretName` | `my-db-keyavalue-redis` | unset (dev Valkey has no auth) |
| c4p `postgresql.host` | `my-db-sql-postgresql.default.svc.cluster.local` | `my-db-sql-postgresql-rw.team-a.svc.cluster.local` |
| c4p `postgresql.secretName` / key | `my-db-sql-postgresql` / `postgres-password` | `my-db-sql-postgresql-superuser` / `password` (CNPG generates the value; `enableSuperuserAccess: true`) |
| all `kafka.url` | `my-mb-kafka.default.svc.cluster.local` | `my-mb-kafka-kafka-bootstrap.team-a.svc.cluster.local` |
| Kafka pod | `my-mb-kafka-0` | `my-mb-kafka-my-mb-kafka-dual-role-0` |
| init SQL | `kubectl apply -f resources/config` (default ns) | `kubectl apply -n team-a -f resources/config` before requesting the SQL Database (CNPG `postInitSQLRefs` reads it) |

## Chapter 5: AWS compositions (run against Floci, not AWS)

Converted to `mode: Pipeline` and provider-upjet-aws v2.8.1 namespaced MRs: `elasticache.aws.m.upbound.io/v1beta1 Cluster`, `rds.aws.m.upbound.io/v1beta1 Instance` (`username: postgres`, `autoGeneratePassword` into `<xr>-postgres-password`), `kafka.aws.m.upbound.io/v1beta1 Cluster` (MSK; client subnets and security groups selected by label `platform.salaboy.com/msk: "true"`, which the original omitted and MSK requires). New `chapter-5/aws/providers.yaml` installs the three family providers; the README uses an `aws.m.upbound.io/v1beta1 ClusterProviderConfig`. Checked with `crossplane render` (function run in Docker) piped to `crossplane resource validate` against the v2.8.1 CRDs: all three MRs validate. (Crossplane CLI v2.5.0 renamed `crossplane beta validate` to `crossplane resource validate`; the XR in `render`'s output fails validation only because `render` drops `spec.parameters` from the echoed XR, and the input XRs validate.) Never applied to AWS; Secret keys unverified. The repo has no GCP compositions.

Follow-up on branch `aws-floci`: the whole AWS tutorial, including the Conference app e2e flow, ran against [Floci](https://github.com/floci-io/floci) 2.1.0 on kind. Changes: the Redis Composition composes an ElastiCache `ReplicationGroup` instead of a `Cluster` ([F080](docs/findings/F080-aws-redis-cluster-to-replicationgroup.md)); `providers.yaml` adds provider-aws-ec2 and new `network.yaml` creates the labelled VPC/Subnets/SG MSK selects ([F081](docs/findings/F081-aws-msk-network-and-ec2-provider.md)); new `init-jobs.yaml` creates `events-topic` and the `proposals` table ([F082](docs/findings/F082-aws-topic-and-table-never-created.md)); `app-values.yaml` has placeholders that the README fills from the MR status and Secrets; Floci-only `floci/providerconfig.yaml` plus a README section ([F083](docs/findings/F083-aws-tutorial-verified-on-floci.md), which also lists Floci's differences from AWS); README warning about reaching VPC endpoints from kind ([F084](docs/findings/F084-aws-endpoints-unreachable-from-kind.md)). Connection Secret keys now verified on Floci: RDS `address`, `host`, `port`, `username`, `endpoint`, `password`; ElastiCache `configuration_endpoint_address` (AWS: `primary_endpoint_address`) and `port`; MSK none.

## Chapter 6: Environment on Crossplane v2 + vcluster 0.37.2

| What | Before | After | Tested |
| --- | --- | --- | --- |
| XRD | `XEnvironment` + claim `Environment`, cluster-scoped | `Environment`, `apiextensions.crossplane.io/v2`, `scope: Namespaced`, no claim; `CONNECT-TO` column is the XR name | PASS |
| vcluster | chart 0.15.7, `syncer.extraArgs` (`--out-kube-config-secret`, `--out-kube-config-server=https://<n>.<n>.svc`, `--tls-san`), `multiNamespaceMode`, `fallbackHostDns` | chart 0.37.2, only `exportKubeConfig.server: https://<name>.<namespace>:443`; vcluster writes Secret `vc-<name>` key `config` | PASS |
| Helm MRs | `helm.crossplane.io/v1beta1 Release`, `v1alpha1 ProviderConfig` | `helm.m.crossplane.io/v1beta1` Release, ProviderConfig (namespaced; `secretRef.namespace` is still required) and `ClusterProviderConfig default` (InjectedIdentity, for the host) | PASS |
| Infra inside the vcluster | Bitnami subcharts | CloudNativePG and Strimzi operator Releases installed inside each vcluster, then the app chart with `install.infrastructure` from `installInfra` | PASS (installInfra=true) |
| App chart | `oci://docker.io/salaboy/conference-app:v1.0.0` | `chart.url` = `chapter-6/charts/conference-app-v1.1.0.tgz` on this branch via raw.githubusercontent.com (chart version bumped v1.0.0 → v1.1.0) | PASS |
| Frontend debug | `services.frontend.debug` | unchanged; verified `/api/features/` returns `"DebugEnabled":"true"` | PASS |
| Deletion | n/a | inner Releases use `managementPolicies: [Observe, Create, Update, LateInitialize]` | PASS |

### Things found while testing chapter 6

- **`exportKubeConfig.server: https://<name>.<namespace>.svc:443` fails TLS**: `x509: certificate is valid for kubernetes.default.svc.cluster.local, kubernetes.default.svc, kubernetes.default, kubernetes, localhost, *.nodes.vcluster.com, *.team-a-dev-env.team-a.nodes.vcluster.com, my-host.com, team-a-dev-env, team-a-dev-env.team-a, not team-a-dev-env.team-a.svc`. `https://<name>.<namespace>:443` works with no `insecure` and no extra SANs. (`controlPlane.proxy.extraSANs` would be the other fix; not tried.)
- **Environment deletion hung** with default management policies: the vcluster Release was deleted first, then the in-vcluster Releases could not connect (`Secret "vc-team-a-dev-env" not found`) and kept their finalizers. Dropping `Delete` from their `managementPolicies` fixed it: on the second cycle every Release, the ProviderConfig and all pods were gone within ~2 minutes.
- **First install of the app chart can fail permanently** (`failed calling webhook "mcluster.cnpg.io" ... connection refused`) because the three Releases inside the vcluster install concurrently. With no `rollbackLimit`, provider-helm left it `failed`; with `rollbackLimit: 3` it retried on the next poll (in the first run I also had to touch an annotation to trigger it sooner; in the second run it recovered in ~1 minute by itself).
- `Environment` `READY=True` means the Releases are deployed, not that the app pods are Ready (Kafka needs a few more minutes).
- vcluster's PVC `data-<name>-0` survives Environment deletion; recreating an Environment with the same name reuses the old vcluster state unless it's deleted.
- A vcluster also creates Secret `vc-config-<name>` (its own config); the kubeconfig is `vc-<name>`, written only once the vcluster pod is running.
- Admin UI (`conference-admin`) not updated: its Go types still write the v1 `Environment` shape. Needs code + image rebuild. UNTESTED.

## Other Bitnami usages

| File | Change | Tested |
| --- | --- | --- |
| `conference-application/*/docker-compose.yaml`, `*/tests/docker-compose.yaml` (6 files) | `bitnami/kafka` → `apache/kafka:4.3.1` with KRaft env (`KAFKA_NODE_ID`, `KAFKA_PROCESS_ROLES`, `KAFKA_CONTROLLER_*`, …); `kafka-topics.sh` → `/opt/kafka/bin/kafka-topics.sh`; dropped the `/bitnami` volume; `bitnami/redis` → `valkey/valkey:9.1.2` (no `ALLOW_EMPTY_PASSWORD`); `bitnami/postgresql` → `postgres:18` | PASS for `c4p-service` infra (postgres init.sql created `proposals`, topic created) and `agenda-service/tests` (stack healthy, agenda item created and read back); others UNTESTED |
| `service-pipeline.go` | same image/env swaps in the Dagger test services | `go vet` compiles (pre-existing vet warning at line 187); not run |
| `helm-chart-pipeline.go` | `helm repo add bitnami` → `helm repo add valkey https://valkey.io/valkey-helm/` | compiles; not run (still pins `alpine/helm:3.12.1`) |

## Not changed (leads)

- `chapter-4/argo-cd/staging/Chart.yaml` depends on the published `oci://docker.io/salaboy/conference-app:v1.0.0` (Bitnami); `staging/values-debug-enabled.yaml` uses Bitnami value paths (`redis.auth.existingSecret`, `postgresql.auth.existingSecret`); `staging-kube/app.yaml` is a `helm template` dump of the old subcharts. Needs the chart republished, then regenerate.
- `chapter-7` (Dapr, `v2.0.0` chart on another branch) README references `conference-redis-master` and the `conference-redis` secret.
- `chapter-8/knative/*.yaml` and `conference-application/*/config-knative/service.yaml`: hosts `redis-master`, `postgres-postgresql`, key `postgres-password`; `chapter-8/knative/README.md` and `chapter-8/argo-rollouts/README.md` `helm install … bitnamicharts`.
- `chapter-9/dora-cloudevents/config/services.yaml`, `resources/components.yaml`: host `postgresql`, secret `postgresql` / `postgres-password` (5 places each).
- `conference-application/from-source/README.md`: Bitnami charts including `nginx-ingress-controller`.
- Translated READMEs (`-es`, `-ja`, `-zh`, `-pt`, `-fr`) still carry the old commands.
- `install.infrastructure=false` with no per-service values fails to render (`nil pointer evaluating interface {}.kafka`); so `team-b-dev-env.yaml` (`installInfra: false`) can't work without values. Pre-existing; UNTESTED here.
- ingress-nginx is installed from `main` of kubernetes/ingress-nginx; the project announced its retirement (UNVERIFIED here). Tekton, Argo CD, Dapr and Knative versions in later chapters were not checked.

## Published artifacts

All images are `linux/amd64` + `linux/arm64`, built with ko (`ko build`, Chainguard static base) and labelled `org.opencontainers.image.source=https://github.com/allensanborn/platforms-on-k8s`. Republish with [`hack/publish-ghcr.sh`](hack/publish-ghcr.sh); it skips any tag that already exists. Package list and visibility: see [F044](docs/findings/F044-image-inventory.md).

| Image | Tag | Index digest | Built from |
| --- | --- | --- | --- |
| `ghcr.io/allensanborn/admin-go-4b1308c49d6627e0dc7e3ffd57f155cc` | `v1.2.0` | `sha256:560a2b3dac55075381ecb796f87c67f931a033e99449901ed50fb01f7b0d2479` | this branch, working tree of `f03c06d` |
| `ghcr.io/allensanborn/agenda-service-0967b907d9920c99918e2b91b91937b3` | `v1.2.0` | `sha256:88f48e0e45cb14c2a0f9483a224ad0a59204a6ed4065b556bfac7045bd213f74` | this branch, working tree of `f03c06d` |
| `ghcr.io/allensanborn/agenda-service-0967b907d9920c99918e2b91b91937b3` | `v2.1.0` | `sha256:e95f0549e36884525e23c99953092943df2b6863ffc13d1d551e8486477e7162` | branch `v2.0.0-bitnami-replacements` @ `a62e4bd` |
| `ghcr.io/allensanborn/c4p-service-a3dc0474cbfa348afcdf47a8eee70ba9` | `v1.2.0` | `sha256:e2e3fc95cbe87cb3bfcdcfa2b9f5e6aa116bcc24b64a77b8735af84fef6c359e` | this branch, working tree of `f03c06d` |
| `ghcr.io/allensanborn/c4p-service-a3dc0474cbfa348afcdf47a8eee70ba9` | `v2.1.0` | `sha256:23c85eaffba0b6c685c0e399d8fb164f05989538ce1cfa8655eb3771ba699180` | branch `v2.0.0-bitnami-replacements` @ `a62e4bd` |
| `ghcr.io/allensanborn/dora-cdevents-endpoint` | `v1.2.0` | `sha256:3eab84d375afe8ce42f64af4b6d7fe228561c0222cf371eb434905e08e772746` | this branch, working tree of `f03c06d` |
| `ghcr.io/allensanborn/dora-cloudevents-endpoint` | `v1.2.0` | `sha256:5d1e0841422ad8912781237b698cd68cced4fe6bb4151e56f243d4b945dde14d` | this branch, working tree of `f03c06d` |
| `ghcr.io/allensanborn/dora-cloudevents-router` | `v1.2.0` | `sha256:6c6bef36c379ef1df0a2d69284d56413e0312268ef92b68ee978bf0e27369be2` | this branch, working tree of `f03c06d` |
| `ghcr.io/allensanborn/dora-deployment-frequency-endpoint` | `v1.2.0` | `sha256:e6ac52b709e26a772a97e17a64b1461b62e1ae84d0f63e4dedd3e06192039f4f` | this branch, working tree of `f03c06d` |
| `ghcr.io/allensanborn/dora-deployment-frequency` | `v1.2.0` | `sha256:3a5518f8c61b162ce9ce10fcaed36da28fb232ec465516f9f459371b9053501c` | this branch, working tree of `f03c06d` |
| `ghcr.io/allensanborn/dora-function-api-server-to-service-deployment` | `v1.2.0` | `sha256:d80385fbedc4b4a954dc992aa4bb1c88031ad3a7f8e13f9a49a4cf8a7d158cdc` | this branch, working tree of `f03c06d` |
| `ghcr.io/allensanborn/frontend-go-1739aa83b5e69d4ccb8a5615830ae66c` | `v1.2.0` | `sha256:ba63fb78e4c828d7a1b87610deee4eaa6a0c7bf8c8f4e846ce4abb09e070a405` | this branch, working tree of `f03c06d` |
| `ghcr.io/allensanborn/frontend-go-1739aa83b5e69d4ccb8a5615830ae66c` | `v1.3.0` | `sha256:dfaea37090ff55697dd627cd7aa45040d2d685fbb0a3b885a24d0ef91cac3199` | this branch, working tree of `f03c06d` |
| `ghcr.io/allensanborn/frontend-go-1739aa83b5e69d4ccb8a5615830ae66c` | `v2.1.0` | `sha256:018646efac46296cc4049682956c45c44725d00469800eefe4a8d61d9f390a75` | branch `v2.0.0-bitnami-replacements` @ `a62e4bd` |
| `ghcr.io/allensanborn/notifications-service-0e27884e01429ab7e350cb5dff61b525` | `v1.2.0` | `sha256:13542dc1ed5586d768bc477bc3ae658f3663b3a71f607b144f5033527781849e` | this branch, working tree of `f03c06d` |
| `ghcr.io/allensanborn/notifications-service-0e27884e01429ab7e350cb5dff61b525` | `v1.3.0` | `sha256:afc1c07c3f457c658ee662615c2b1420a9af110ebb91350b23e516a0b95db417` | this branch, working tree of `f03c06d` |
| `ghcr.io/allensanborn/notifications-service-0e27884e01429ab7e350cb5dff61b525` | `v2.1.0` | `sha256:af901dd2dc9b4c0448e957f04dc9941f19ab89f220e89ed9ee1e2e4ff8230c07` | branch `v2.0.0-bitnami-replacements` @ `a62e4bd` |

Charts:

| Chart | Version | Digest | Status |
| --- | --- | --- | --- |
| `oci://ghcr.io/allensanborn/conference-app` | `v1.1.0` | `sha256:a7e7b8e3e07fd9459bc56cc711887945ff2a2ac0d70acf0b2ccdcc39100b4246` | public; Valkey/CNPG/Strimzi, still `salaboy/*:v1.0.0` images |
| `oci://ghcr.io/allensanborn/conference-app` | `v1.2.0` | `sha256:5ca6ccdae678086f78a7f1654528d3cf484451095ba4c55e17ea4d230af7e0fc` | public package; `ghcr.io/allensanborn/*:v1.2.0` images, init containers, F020 fix, no Keptn labels |
| `oci://ghcr.io/allensanborn/conference-app` | `v2.1.0` | `sha256:06c52d285613da67107784bfb2a730ab739fece6439b19aa62ebd6702c2c6d70` | public package; Dapr line, from branch `v2.0.0-bitnami-replacements` |
| `oci://ghcr.io/allensanborn/conference-admin` | `v1.2.0` | `sha256:db1d09a5c861284e0830dfb7399799742141c78f625ef0311427c3d2d0308a0b` | private until flipped; Admin UI on Crossplane v2 |

Each chart passed an install from its packaged `.tgz` (images pulled with a temporary pull secret) before it was pushed: v1.2.0 e2e PASS with 0 restarts, v2.1.0 e2e PASS with Dapr 1.11.0, and conference-admin was Running with the right namespace settings.
