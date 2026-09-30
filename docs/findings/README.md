# Findings

Everything found while updating this fork (branch `crossplane-v2-and-bitnami-replacements`; chapter 7's Dapr version is fixed on branch `v2.0.0-bitnami-replacements`, cut from upstream `v2.0.0`) for Bitnami's image removal and Crossplane v2, one file per finding. [`UPDATE-NOTES.md`](../../UPDATE-NOTES.md) is the chronological log. Status: **fixed** (changed here and tested unless the file says otherwise), **documented** (explained, no code change needed or possible), **open** (not fixed), **wontfix**.

Sources the findings were checked against: the llm-wiki page *Platform Engineering on Kubernetes — Crossplane chapters, v2 edition* (F015, F016, F017, F018, F019, F028, F029 correct it) and the Bitnami replacement inventory `charts.md` (F010, F011 and the tested items in F009 and F005 extend it).

| ID | Title | Chapter | Severity | Status | Fix commit |
| --- | --- | --- | --- | --- | --- |
| [F001](F001-bitnami-images-removed.md) | Bitnami's pinned images return 404, so the chart's Redis/PostgreSQL/Kafka never start | 2 (and 4-9 via the chart) | high | fixed | 27da304 |
| [F002](F002-published-chart-embeds-bitnami.md) | The published `oci://docker.io/salaboy/conference-app:v1.0.0` still embeds the Bitnami subcharts | 2, 4, 5, 6, 9 | high | fixed | 45216f3 |
| [F003](F003-stale-vendored-subcharts.md) | Vendored subchart tarballs didn't match Chart.yaml | 2 | low | fixed | 27da304 |
| [F004](F004-ingress-nginx-kind-nodeselector.md) | ingress-nginx's kind manifest no longer pins the controller to the `ingress-ready` node | 2 (and every chapter reusing its cluster) | medium | fixed | 27da304 |
| [F005](F005-services-crashloop-until-infra-ready.md) | Services crash-loop until Kafka/PostgreSQL/Redis are reachable | 2, 5, 6 | medium | fixed | 45216f3 |
| [F006](F006-frontend-exits-on-kafka-read-error.md) | Frontend exits on any Kafka read error, including a transient `Not Coordinator For Group` | 2, 5, 6 | medium | fixed in code; image not published | 3256cfc |
| [F007](F007-kafka-bootstrap-timeout-on-kind.md) | Kafka bootstrap Service timed out for minutes after Kafka was `Ready` (kindnet NetworkPolicy suspected) | 2, 4 | medium | documented (workaround; cause not proven) | — |
| [F008](F008-strimzi-startup-time-on-kind.md) | Strimzi Kafka takes 1.5-5 minutes to become Ready on kind | 2, 5, 6 | info | documented | 27da304 |
| [F009](F009-c4p-needs-postgres-superuser.md) | c4p-service needs user and database `postgres`, so it uses CloudNativePG's superuser Secret | 2, 5, 6 | medium | fixed | 27da304 |
| [F010](F010-helm-dependency-build-needs-repo.md) | `helm dependency build` fails for the Valkey dependency unless its repo is added | 2 | low | documented | 7d71eb2 |
| [F011](F011-strimzi-pvcs-retained.md) | Strimzi keeps Kafka PVCs unless `deleteClaim: true` | 2, 5 | low | fixed | 27da304 |
| [F012](F012-crossplane-v2-compositions.md) | Chapter 5/6 Compositions and XRDs don't apply on Crossplane v2 | 5, 6 | high | fixed | 7d71eb2, b2ee1fc |
| [F013](F013-crossplane-aggregated-rbac.md) | Crossplane needs aggregated RBAC for composed operator resources | 5 | medium | fixed | 7d71eb2 |
| [F014](F014-vcluster-values-schema.md) | vcluster 0.15.7 values (`syncer.extraArgs`, `multiNamespaceMode`, `fallbackHostDns`) are obsolete | 6 | high | fixed | b2ee1fc |
| [F015](F015-vcluster-kubeconfig-san.md) | `exportKubeConfig.server: https://<name>.<ns>.svc` fails TLS verification | 6 | high | fixed | b2ee1fc |
| [F016](F016-environment-deletion-hangs.md) | Deleting an Environment hangs on the in-vcluster Releases' finalizers | 6 | high | fixed | b2ee1fc |
| [F017](F017-provider-helm-failed-release-no-retry.md) | A provider-helm Release whose first install fails stays `failed` | 6 | medium | fixed | b2ee1fc, 07d8fa2 |
| [F018](F018-operators-inside-vcluster.md) | The operator-based chart needs CNPG and Strimzi inside each vcluster | 6 | medium | fixed | b2ee1fc |
| [F019](F019-frontend-debug-value-key.md) | The Conference chart's frontend debug value is `services.frontend.debug` | 6 | low | documented | b2ee1fc |
| [F020](F020-infra-false-needs-values.md) | `install.infrastructure=false` without per-service values fails to render | 6 | low | open | — |
| [F021](F021-admin-ui-v1-environment.md) | Admin UI still writes the Crossplane v1 `Environment` shape | 6 | medium | open | — |
| [F022](F022-aws-compositions.md) | AWS compositions used an archived provider and an incomplete MSK spec | 5 (aws) | medium | fixed (untested against AWS) | 12e796d |
| [F023](F023-crossplane-cli-validate-renamed.md) | `crossplane beta validate` is now `crossplane resource validate`; CLI moved to cli.crossplane.io | 5 | info | documented | — |
| [F024](F024-docker-compose-bitnami.md) | docker-compose files and Dagger pipelines used Bitnami images and env | dev loop | medium | fixed | d84fe7d |
| [F025](F025-frontend-go-mod-stale.md) | frontend-go's go.mod needs `go mod tidy` before it builds | dev loop | low | fixed | 3256cfc |
| [F026](F026-workflows-publish-main-only.md) | GitHub workflows publish to salaboy's Docker Hub, but only on `main` | n/a | info | documented | — |
| [F027](F027-environment-ready-semantics.md) | Environment `READY` means Releases deployed, not app ready; vcluster PVC survives deletion | 6 | low | documented | b2ee1fc |
| [F028](F028-page-cnpg-app-secret.md) | v2 edition page: composed CNPG `-app` Secret and no init SQL | 5 | medium | documented (page) / fixed (repo) | 7d71eb2 |
| [F029](F029-page-messagebroker-and-keyvalue.md) | v2 edition page: MessageBroker unwritten; keyvalue image | 5 | low | documented | 7d71eb2 |
| [F030](F030-provider-helm-namespaced-providerconfig.md) | provider-helm v1.4.0 namespaced ProviderConfig still requires `secretRef.namespace` | 6 | info | documented | b2ee1fc |
| [F031](F031-tool-version-drift.md) | Tool versions drifted in chapters not updated here | 4, 7, 8, 9 | info | documented | — |
| [F032](F032-argocd-client-side-apply-too-long.md) | Argo CD install fails with client-side apply (CRD annotation too long) | 4 | medium | fixed | fa1df29 |
| [F033](F033-argocd-staging-bitnami-values.md) | Chapter-4 staging config used Bitnami value paths and a stale manifest dump | 4 | high | fixed | fa1df29 |
| [F034](F034-chapter8-bitnami-infra.md) | Chapter 8 installed Kafka, PostgreSQL and Redis from Bitnami charts | 8 | high | fixed | 571afcd |
| [F035](F035-argo-rollouts-client-side-apply.md) | Argo Rollouts install fails with client-side apply (CRD annotation too long) | 8 | medium | fixed | 571afcd |
| [F036](F036-chapter8-name-clash-and-knative-drift.md) | Knative and Argo Rollouts tutorials clash on one cluster; Knative pinned at 1.10 | 8 | low | documented | 571afcd |
| [F037](F037-chapter9-dora-bitnami-postgresql.md) | Chapter 9 DORA demo installed PostgreSQL from the Bitnami chart | 9 | high | fixed | c4e4279 |
| [F038](F038-keptn-klt-chart-renamed.md) | Keptn tutorial installs the frozen `klt` chart | 9 | medium | documented (untested) |  |
| [F039](F039-chapter7-v2-chart-bitnami.md) | Chapter 7's Dapr chart (v2.0.0) has the same Bitnami dependencies | 7 | high | fixed on branch `v2.0.0-bitnami-replacements` | a62e4bd (other branch) |
| [F040](F040-keptn-observability-stack.md) | The Keptn chapter's observability install no longer completes | 9 | medium | open (two of three blockers fixed) | 47641bd |
