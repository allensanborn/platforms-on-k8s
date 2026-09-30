# F029: v2 edition page: MessageBroker unwritten; keyvalue image

- **Chapter:** 5
- **Severity:** low
- **Status:** documented
- **Fix commit:** 7d71eb2
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

The page left the Strimzi MessageBroker Composition unwritten and used `redis:8.2` for keyvalue.

## Root cause

Unverified at the time.

## Evidence

Chapter-5 test: MessageBroker `READY True` in ~99s; app events flow.

## Fix or workaround

Written and tested: `KafkaNodePool` (`strimzi.io/cluster` patched from the XR name, readiness None), `Kafka` (default Ready), `KafkaTopic` (`topicName: events-topic`). Keyvalue uses `valkey/valkey:9.1.2` plus a TCP readinessProbe.

## How to verify

Chapter-5 README flow.

## Upstream relevance

No (wiki-side).

