# F002: The published `oci://docker.io/salaboy/conference-app:v1.0.0` still embeds the Bitnami subcharts

- **Chapter:** 2, 4, 5, 6, 9
- **Severity:** high
- **Status:** fixed
- **Fix commit:** 45216f3
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

Chapters 2, 4, 5, 6 and 9 install `oci://docker.io/salaboy/conference-app --version v1.0.0` (or depend on it), which pulls the removed Bitnami images (F001).

## Root cause

Only the chart's owner can republish to `docker.io/salaboy`.

## Evidence

`helm show chart` of the upstream chart lists the three Bitnami dependencies; the images 404 (F001).

## Fix or workaround

This fork publishes the updated chart as `oci://ghcr.io/allensanborn/conference-app` version `v1.1.0` (the chart's own leading-v scheme; can't collide with upstream `v1.0.0` or the chapter-7 `v2.0.0` line). Digest `sha256:a7e7b8e3e07fd9459bc56cc711887945ff2a2ac0d70acf0b2ccdcc39100b4246`. `Chart.yaml` `sources[0]` sets the `org.opencontainers.image.source` annotation, which linked the package to this repository. READMEs and the chapter-6 Composition point at it; each README keeps a one-line local-path alternative. The package was pushed private. GitHub's REST API has no endpoint for package visibility (`PATCH /user/packages/container/conference-app/visibility` returns 404), so the owner switched it to Public in the UI on 2026-09-30. After that, an anonymous manifest request returned 200. Chapters 5 and 6 then passed with Helm's and Docker's credentials disabled, and Argo CD pulled the chapter-4 umbrella dependency. The chart README inside the pushed v1.1.0 artifact still shows the old install line (edited after packaging).

## How to verify

`helm show chart oci://ghcr.io/allensanborn/conference-app --version v1.1.0` with no registry credentials.

## Upstream relevance

High for upstream: republishing `salaboy/conference-app` with these changes would fix chapters 2-9 in one step.

