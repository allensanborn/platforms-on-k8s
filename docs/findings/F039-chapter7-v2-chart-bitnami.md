# F039: Chapter 7's Dapr chart (v2.0.0) has the same Bitnami dependencies

- **Chapter:** 7
- **Severity:** high
- **Status:** fixed on branch `v2.0.0-bitnami-replacements` (chart not published)
- **Fix commit:** a62e4bd (branch `v2.0.0-bitnami-replacements`)
- **Found:** 2026-09-30

## Symptom

Chapter 7 installs `oci://docker.io/salaboy/conference-app --version v2.0.0`. That chart lives on the upstream `v2.0.0` branch and depends on Bitnami redis 17.11.3, postgresql 12.5.9 and kafka 22.1.5 ([F001](F001-bitnami-images-removed.md)). Its Dapr Components point at `<rel>-redis-master` and `<rel>-kafka:9092`.

## Root cause

F001. The `v2.0.0` branch diverged from `main`: 179 files changed, including a Dapr rewrite of the services. So the fix lives on a branch cut from it rather than being mixed into `main`.

## Evidence

Fresh kind cluster `pek-ch7` with Dapr 1.11.0 (`helm upgrade --install dapr dapr --repo https://dapr.github.io/helm-charts/ --version=1.11.0`), CNPG and Strimzi:
- The chart installed from the branch. All pods ran 2/2 (daprd sidecars); `kubectl get components` listed `conference-agenda-service-statestore` and `conference-conference-pubsub`, and daprd logged `Component loaded … (pubsub.kafka/v1)`.
- e2e flow: proposal `DECIDED`, 1 agenda item, 1 notification, events `new-proposal`, `new-agenda-item`, `proposal-approved`, `notification-sent`.
- Dapr 1.11's Kafka client works against Kafka 4.3.1.
- Restarts: 10 without init containers, 4 with them. The remaining restarts come from daprd: `init timeout for component conference-conference-pubsub exceeded after 5s` → `daprd process will exit gracefully`, and the app then panics on `error creating connection to '127.0.0.1:50001'`. This happens while Kafka is reachable but not yet serving metadata.

## Fix or workaround

On branch `v2.0.0-bitnami-replacements`:
- The same chart changes as `main`: Valkey `alias: redis`, `templates/infrastructure.yaml`, and `wait-for-dependencies` init containers.
- Chart version `v2.1.0`.
- Dapr statestore `redisHost` → `<rel>-redis:6379`; pubsub `brokers` → `<rel>-kafka-bootstrap:9092`; c4p → `<rel>-postgresql-rw` with `<rel>-postgresql-superuser`/`password`.
- The chapter-7 README installs the operators and the chart from the branch path.

**Not done:** publishing `v2.1.0` to GHCR. The user authorized `v1.1.0` only, so this is a user decision. To publish:

```
helm package conference-application/helm/conference-app
helm push conference-app-v2.1.0.tgz oci://ghcr.io/allensanborn
```

## How to verify

Check out `v2.0.0-bitnami-replacements`, then follow `chapter-7/README.md` on a fresh kind cluster.

## Upstream relevance

Yes. The upstream fix would be a republished `v2.0.0` line.
