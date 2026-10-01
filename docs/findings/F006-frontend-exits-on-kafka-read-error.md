# F006: Frontend exits on any Kafka read error, including a transient `Not Coordinator For Group`

- **Chapter:** 2, 5, 6
- **Severity:** medium
- **Status:** fixed
- **Fix commit:** 3256cfc (image `ghcr.io/allensanborn/frontend-go-1739aa83b5e69d4ccb8a5615830ae66c:v1.2.0`, used by chart v1.2.0)
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`frontend` restarts with `[16] Not Coordinator For Group` right after Kafka comes up, and again whenever the broker restarts; the HTTP server dies with the consumer goroutine.

## Root cause

`consumeFromKafka` called `log.Fatalln(err)` on every `ReadMessage` error.

## Evidence

Broker restart test on `pek-m1` (`kubectl delete pod conference-conference-dual-role-0`): original image `salaboy/frontend-go-…:v1.0.0` → `RESTARTS 3`; fixed image → `RESTARTS 0`, log `failed to read from Kafka, retrying: … connection refused`, then events kept flowing.

Also seen on a normal config change: `helm upgrade … -f values-debug-enabled.yaml` in chapter 4 gave the new frontend pod 2 restarts, because the old pod was still in consumer group `app` and the rebalance returned a read error.

## Fix or workaround

`frontend.go`: read errors are logged and retried after 2s, `io.EOF` (reader closed) returns; the reader is taken through a small interface so `consume_test.go` can drive it with a fake. `go.mod` moved from `go 1.19` to `go 1.21` because the module didn't build otherwise ([F025](F025-frontend-go-mod-stale.md)). Published 2026-09-30 as `ghcr.io/allensanborn/frontend-go-1739aa83b5e69d4ccb8a5615830ae66c:v1.2.0` (and `v1.3.0`); chart `v1.2.0` uses it.

## How to verify

`cd conference-application/frontend-go && go test -mod=mod -run TestConsumeFromKafka .`; on a cluster, patch the frontend image to the local build and delete the broker pod.

## Upstream relevance

Yes (same pattern may exist in other consumers; not audited).

