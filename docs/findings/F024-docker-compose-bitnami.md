# F024: docker-compose files and Dagger pipelines used Bitnami images and env

- **Chapter:** dev loop
- **Severity:** medium
- **Status:** fixed
- **Fix commit:** d84fe7d
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`docker compose up` fails to pull `docker.io/bitnami/*` (F001).

## Root cause

Same as F001; the files also relied on Bitnami-only env (`ALLOW_PLAINTEXT_LISTENER`, `KAFKA_CFG_*`, `ALLOW_EMPTY_PASSWORD`).

## Evidence

c4p infra stack: postgres ran `init.sql` (`proposals` table), topic created; agenda tests stack healthy and an agenda item round-tripped.

## Fix or workaround

`apache/kafka:4.3.1` with KRaft env (`KAFKA_NODE_ID`, `KAFKA_PROCESS_ROLES`, `KAFKA_CONTROLLER_*`, …) and `/opt/kafka/bin/kafka-topics.sh`; `valkey/valkey:9.1.2`; `postgres:18`. Same swaps in `service-pipeline.go`; `helm-chart-pipeline.go` adds the valkey repo instead of bitnami.

## How to verify

`cd conference-application/c4p-service && docker compose up -d --wait postgresql kafka && docker compose up init-kafka`.

## Upstream relevance

Yes.

