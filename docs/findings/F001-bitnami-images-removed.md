# F001: Bitnami's pinned images return 404, so the chart's Redis/PostgreSQL/Kafka never start

- **Chapter:** 2 (and 4-9 via the chart)
- **Severity:** high
- **Status:** fixed
- **Fix commit:** 27da304
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

Pods of the Bitnami subcharts sit in `ImagePullBackOff`. `docker compose up` fails with `failed to resolve reference "docker.io/bitnami/kafka:3.4.1-debian-11-r0": not found` (observed 2026-09-30).

## Root cause

Bitnami stopped publishing versioned images to `docker.io/bitnami` on 2025-08-28 ([bitnami/charts#35164](https://github.com/bitnami/charts/issues/35164)). The pinned tags (`redis:7.0.11-debian-11-r12`, `postgresql:15.3.0-debian-11-r17`, `kafka:3.4.1-debian-11-r0`) exist only under `docker.io/bitnamilegacy`, which gets no updates. `docker.io/bitnami/kafka` has no tags at all.

## Evidence

`docker compose -p pek-c4p up` on the original `c4p-service/docker-compose.yaml`: `Error response from daemon: failed to resolve reference "docker.io/bitnami/kafka:3.4.1-debian-11-r0": ... not found`.

## Fix or workaround

Chart dependencies replaced: Redis → official Valkey chart `valkey` 0.12.0 (`alias: redis`); PostgreSQL → CloudNativePG `Cluster` (operator chart 0.29.1 / 1.30.1); Kafka → Strimzi `Kafka` + `KafkaNodePool` + `KafkaTopic` (operator 1.2.0, `kafka.strimzi.io/v1`, KRaft, Kafka 4.3.1), in `templates/infrastructure.yaml`. The operators are prerequisites installed once per cluster (chapter-2 README). Name mapping in [UPDATE-NOTES.md](../../UPDATE-NOTES.md#names-release-conference-namespace-default).

## How to verify

Chapter 2 README from a fresh kind cluster; all pods `Running`, then submit/approve a proposal (see [F005](F005-services-crashloop-until-infra-ready.md) for the e2e script).

## Upstream relevance

High. Every chapter that installs the chart is broken upstream today.

