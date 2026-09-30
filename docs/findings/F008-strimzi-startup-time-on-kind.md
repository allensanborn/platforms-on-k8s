# F008: Strimzi Kafka takes 1.5-5 minutes to become Ready on kind

- **Chapter:** 2, 5, 6
- **Severity:** info
- **Status:** documented
- **Fix commit:** 27da304
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`kubectl wait kafka/conference --for=condition=Ready` needed about 5 minutes on the first cluster, 1-1.5 minutes on later ones (images cached).

## Root cause

Operator → broker/controller pod → entity operator (topic operator), each pulling an image; heavier than one Bitnami pod.

## Evidence

Timings from `pek-ch2`, `pek-ch5`, `pek-m1` on 2026-09-30.

## Fix or workaround

README says so and shows `kubectl wait` commands; `kind-load.sh` preloads the Strimzi images.

## How to verify

n/a

## Upstream relevance

Yes (documentation).

