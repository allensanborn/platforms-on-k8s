# F043: Upstream's published `conference-app:v3.0.0` has no source in the repo and doesn't include infrastructure

- **Chapter:** 7 (and later)
- **Severity:** info
- **Status:** documented
- **Fix commit:** —
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

Docker Hub `salaboy/conference-app` has tags `v0.9.9`, `v1.0.0`, `v2.0.0` and `v3.0.0`. There is no `v3.0.0` branch, and no `Chart.yaml` with that version appears anywhere in git history (`git log --all -S v3.0.0 -- '*Chart.yaml'` is empty).

## Root cause

Published from an unpublished checkout.

## Evidence

`helm pull oci://registry-1.docker.io/salaboy/conference-app --version v3.0.0` (digest `sha256:e0d4b4c0dc2900dc638acedcac43be03df5ef05e718278ba7c2453ae9c03e188`, pushed 2023-08-26):
- The description is "Conference App (with Knative, Dapr and OpenFeature)".
- The services are Knative `Service`s with Dapr annotations. It also has Dapr pubsub/statestore/subscription components and flagd.
- There are **no dependencies and no infrastructure**: c4p expects `<rel>-postgresql.default.svc.cluster.local`.
- Images: the Dapr line, `salaboy/*:v2.0.0`.

Other tag dates:
- `v2.0.0`: 2023-07-30
- `v0.9.9`: 2023-09-03T20:18 (after `v1.0.0`, which is 2023-09-03T19:17)

Upstream branches: `main`, `v1.1.0` (source of the book's `v1.1.0` images, see [F046](F046-chapter8-demo-versions.md)), `v2.0.0`, and a few feature branches.

## Fix or workaround

None needed. v3.0.0 doesn't fix anything this fork fixes: it has no Redis/PostgreSQL/Kafka at all, and its images are the Dapr `v2.0.0` ones. This fork doesn't reproduce a Knative+Dapr chart; its chapter-8 Knative manifests and chapter-7 Dapr chart (`v2.1.0`) cover the same ground separately. The fork's own chart tags (`v1.1.0`, `v1.2.0`, `v2.1.0`) don't collide with upstream's.

## How to verify

`helm show chart oci://registry-1.docker.io/salaboy/conference-app --version v3.0.0`.

## Upstream relevance

Yes: upstream could commit the v3 chart's source.
