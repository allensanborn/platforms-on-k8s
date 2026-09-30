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
- 16:37 docker-compose files and Dagger pipelines: images replaced; two compose stacks brought up locally.
- 16:40 all `pek-` clusters deleted.
- 16:44 chart v1.1.0 with `wait-for-dependencies` init containers ([F005](docs/findings/F005-services-crashloop-until-infra-ready.md)) installed from the packaged `.tgz` on fresh cluster `pek-m1`: 0 restarts, e2e PASS.
- 16:47 chart pushed to `oci://ghcr.io/allensanborn/conference-app:v1.1.0` (digest `sha256:a7e7b8e3e07fd9459bc56cc711887945ff2a2ac0d70acf0b2ccdcc39100b4246`), linked to this repo; still **private** ([F002](docs/findings/F002-published-chart-embeds-bitnami.md)). READMEs repointed.
- 16:50 frontend-go Kafka read retry ([F006](docs/findings/F006-frontend-exits-on-kafka-read-error.md)): unit test passes; local ko build loaded into kind survived a broker restart with 0 restarts (original image: 3). Not published.
- 16:53 findings log `docs/findings/` created and backfilled (F001-F031).
- 17:05 chapter 4: Argo CD v3.5.3 (needs `--server-side`, [F032](docs/findings/F032-argocd-client-side-apply-too-long.md)); staging umbrella on GHCR v1.1.0 installed with Helm and switched to debug values: PASS; Argo CD sync of `staging-kube` from this branch: Synced/Healthy, e2e PASS after F007 recurred ([F033](docs/findings/F033-argocd-staging-bitnami-values.md)). Argo CD sync of the umbrella chart is blocked until the GHCR package is public.

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

## Chapter 5: AWS compositions (UNTESTED)

Converted to `mode: Pipeline` and provider-upjet-aws v2.8.1 namespaced MRs: `elasticache.aws.m.upbound.io/v1beta1 Cluster`, `rds.aws.m.upbound.io/v1beta1 Instance` (`username: postgres`, `autoGeneratePassword` into `<xr>-postgres-password`), `kafka.aws.m.upbound.io/v1beta1 Cluster` (MSK; client subnets and security groups selected by label `platform.salaboy.com/msk: "true"`, which the original omitted and MSK requires). New `chapter-5/aws/providers.yaml` installs the three family providers; the README uses an `aws.m.upbound.io/v1beta1 ClusterProviderConfig`. Checked with `crossplane render` (function run in Docker) piped to `crossplane resource validate` against the v2.8.1 CRDs: all three MRs validate. (Crossplane CLI v2.5.0 renamed `crossplane beta validate` to `crossplane resource validate`; the XR in `render`'s output fails validation only because `render` drops `spec.parameters` from the echoed XR, and the input XRs validate.) Never applied to AWS; Secret keys unverified. The repo has no GCP compositions.

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
