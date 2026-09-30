# F007: Kafka bootstrap Service timed out for minutes after Kafka was `Ready` (kindnet NetworkPolicy suspected)

- **Chapter:** 2, 4
- **Severity:** medium
- **Status:** documented (workaround; cause not proven)
- **Fix commit:** —
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`panic: failed to dial: … conference-kafka-bootstrap.default.svc.cluster.local:9092: dial tcp 10.96.208.164:9092: i/o timeout`; `nc -zv -w 5 conference-kafka-bootstrap 9092` timed out from a busybox pod, while the broker accepted connections from inside its own pod. The broker log also had `UnknownHostException` for its own headless name.

## Root cause

Not proven. Strimzi's NetworkPolicy allows 9092 from anywhere, so a correct implementation would never block it. The evidence points at kindnet's NetworkPolicy enforcement giving a wrong verdict for the broker pod for several minutes after it starts, possibly from a stale informer cache (its watches were dropping on a busy 4-node kind cluster). It happened on 2 of 6 clusters.

## Evidence

Reproduced a second time on 2026-09-30 (~17:05, cluster `pek-m1`, Kafka created by Argo CD from `chapter-4/argo-cd/staging-kube`): c4p logged `An error occured while writing the message to Kafka: dial tcp 10.96.149.183:9092: i/o timeout` and returned HTTP 500.
- `nc -zv -w 4 10.244.2.21 9092` (broker pod IP) timed out from pods on every node, including a pod labelled `strimzi.io/name=conference-entity-operator`, which the policy explicitly allows. Port 9091 timed out too.
- The broker node itself (`docker exec pek-m1-worker3 bash -c '</dev/tcp/10.244.2.21/9092'`) and the broker pod itself could connect. Pods without a NetworkPolicy on the same node were reachable.
- kindnet (`kindnetd:v20251212-v0.29.0-alpha-105-g20ccfc88`) enforces NetworkPolicy by adding selected pod IPs to the `podips-v4` set in table `inet kindnet-network-policies` and sending their packets to nfqueue 101 for a userspace verdict. Its log on the broker's node showed `watch ended with error … http2: client connection lost` for NetworkPolicy, Namespace and Node informers.
- After deleting both Strimzi NetworkPolicies (and upgrading the operator with `generateNetworkPolicy=false`), the broker IP left the set, and ~2 minutes later connections from all three workers succeeded. The e2e flow then passed.
- First occurrence: 2026-09-30 15:40-15:48, cluster `pek-ch2`.

## Fix or workaround

Workaround, documented in the chapter-2 README troubleshooting note: on kind, install Strimzi with `--set generateNetworkPolicy=false`, or delete the `<cluster>-network-policy-kafka` policy and wait ~2 minutes. With the chart's init containers ([F005](F005-services-crashloop-until-infra-ready.md)) the services wait instead of crash-looping, but a request can still fail (HTTP 500) while the path is blocked.

## How to verify

`kubectl run nt --rm -i --restart=Never --image=busybox:1.36 -- nc -zv -w 4 conference-kafka-bootstrap 9092`.

## Upstream relevance

Maybe; mention in a troubleshooting note.

