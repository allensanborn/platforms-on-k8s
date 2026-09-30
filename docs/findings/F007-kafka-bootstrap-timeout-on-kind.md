# F007: Kafka bootstrap Service timed out for ~5 minutes after Kafka was `Ready` (first run only)

- **Chapter:** 2
- **Severity:** low
- **Status:** documented (cause not identified)
- **Fix commit:** —
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`panic: failed to dial: … conference-kafka-bootstrap.default.svc.cluster.local:9092: dial tcp 10.96.208.164:9092: i/o timeout`; `nc -zv -w 5 conference-kafka-bootstrap 9092` timed out from a busybox pod, while the broker accepted connections from inside its own pod. The broker log also had `UnknownHostException` for its own headless name.

## Root cause

Unknown. Strimzi's NetworkPolicy allows 9092 from anywhere; after deleting it (Strimzi re-created it two minutes later) connections worked and kept working with the policy back. kindnet's NetworkPolicy enforcement (kindnetd v20251212) is the suspect. Did not recur on 4 later clusters.

## Evidence

Session log 2026-09-30 15:40-15:48, cluster `pek-ch2`.

## Fix or workaround

None needed so far; the init containers ([F005](F005-services-crashloop-until-infra-ready.md)) would now wait instead of crash. If it recurs: `kubectl delete networkpolicy <cluster>-network-policy-kafka`, or install Strimzi with `--set generateNetworkPolicy=false` on kind.

## How to verify

`kubectl run nt --rm -i --restart=Never --image=busybox:1.36 -- nc -zv -w 4 conference-kafka-bootstrap 9092`.

## Upstream relevance

Maybe; mention in a troubleshooting note.

