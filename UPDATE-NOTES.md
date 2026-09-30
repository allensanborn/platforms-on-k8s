# Update notes: Bitnami replacements and Crossplane v2

Branch `crossplane-v2-and-bitnami-replacements` of a fork of `salaboy/platforms-on-k8s`, started 2026-09-30.

Why: Bitnami stopped publishing versioned images to `docker.io/bitnami` in August 2025, so the book's pinned Redis, PostgreSQL and Kafka images return 404 and the pods sit in `ImagePullBackOff`. Crossplane v2 removed native patch-and-transform, cluster-scoped-by-default XRs and XR connection secrets, so the chapter 5 and 6 compositions no longer apply. Every change below was tested on a local kind cluster (kind v0.31.0, Kubernetes v1.35.0) unless marked UNTESTED.

## Progress log

- 15:29 fork + clone, branch created.
- 15:50 chapter 2 chart: PASS on kind cluster `pek-ch2` (all pods Ready, proposal submitted and approved, agenda item created, notification sent, 4 events on `events-topic`).

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
