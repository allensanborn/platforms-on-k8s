# F005: Services crash-loop until Kafka/PostgreSQL/Redis are reachable

- **Chapter:** 2, 5, 6
- **Severity:** medium
- **Status:** fixed
- **Fix commit:** 45216f3
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

After `helm install`, agenda/c4p/notifications/frontend show 4-6 `RESTARTS` and `CrashLoopBackOff` for minutes. Logs: `panic: failed to dial: failed to open connection to conference-kafka-bootstrap.default.svc.cluster.local:9092: ... connection refused` from `main.isKafkaAlive`.

## Root cause

By design the services panic when Kafka isn't reachable at startup (`c4p-service.go`: `restarting until it is healthy`). With operator-managed infrastructure Kafka takes 1-5 minutes on kind ([F008](F008-strimzi-startup-time-on-kind.md)), so the services churn through restart backoff and can sit in backoff after Kafka is ready.

## Evidence

Chapter-2 run 1: agenda 5 restarts, c4p 4, notifications 4, frontend 6 (and CrashLoopBackOff).

## Fix or workaround

Chart template helper `conference-app.waitFor` adds a `wait-for-dependencies` init container (busybox 1.37, `nc -z` loop) to each service: Kafka bootstrap for all four, plus Redis for agenda and PostgreSQL `-rw` for c4p. Hosts come from the release names (infrastructure mode) or the `*.url`/`*.host` values (external mode; `:9092`/`:6379`/`:5432` appended when no port is given). No service code change.

## How to verify

Fresh cluster, `helm install conference oci://ghcr.io/allensanborn/conference-app --version v1.1.0`; all pods `RESTARTS 0` (observed on `pek-m1`, 2026-09-30). `.scratch`-style e2e: POST a proposal, approve it, read agenda, notifications and `/api/events/` (4 events).

## Upstream relevance

Yes.

