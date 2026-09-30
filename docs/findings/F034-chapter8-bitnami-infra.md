# F034: Chapter 8 installed Kafka, PostgreSQL and Redis from Bitnami charts

- **Chapter:** 8
- **Severity:** high
- **Status:** fixed
- **Fix commit:** PENDING
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`helm install kafka|postgresql|redis oci://registry-1.docker.io/bitnamicharts/…` pull removed images ([F001](F001-bitnami-images-removed.md)); the Knative Services and Argo Rollouts point at `kafka`, `redis-master`, `postgresql` / `postgres-password`.

## Root cause

F001.

## Evidence

Cluster `pek-ch8` (the chapter's single-node kind config, Knative Serving 1.10.2 + Kourier 1.10.0), 2026-09-30:
- `kubectl get ksvc` showed all four `READY True`.
- e2e via `http://frontend.default.127.0.0.1.sslip.io`: proposal `DECIDED`, 1 agenda item, 1 notification, 4 events.
- Canary (image patch to `v1.1.0` + 50/50 traffic): 12 requests → 5 `1.0.0`, 7 `1.1.0`.
- Argo Rollouts v1.10.0: the canary went through set image → `Paused - CanaryPauseStep` → promote → `Healthy` at SetWeight 100 on v1.1.0. The blue-green went through `Paused - BlueGreenPause` → promote → v1.1.0 `stable, active`.

## Fix or workaround

New `chapter-8/knative/infrastructure/{kafka,postgresql,redis}.yaml`: a Strimzi `Kafka` named `kafka` (bootstrap `kafka-kafka-bootstrap`), a CNPG `Cluster` `postgresql` (`postgresql-rw`, Secret `postgresql-superuser`/`password`, init SQL via `postInitSQLRefs`), and a Valkey Deployment/Service `redis` (password from Secret `redis`/`redis-password`). They live in a subdirectory so `kubectl apply -f knative/` doesn't pick them up. The ksvc and Rollout env vars and the READMEs are updated. The pod listing in the README is from the real run.

## How to verify

Follow `chapter-8/knative/README.md` on a fresh cluster.

## Upstream relevance

Yes.
