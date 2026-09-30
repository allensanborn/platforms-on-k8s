# F037: Chapter 9 DORA demo installed PostgreSQL from the Bitnami chart

- **Chapter:** 9
- **Severity:** high
- **Status:** fixed
- **Fix commit:** c4e4279
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`helm install postgresql oci://registry-1.docker.io/bitnamicharts/postgresql --version 12.5.7 …` pulls removed images ([F001](F001-bitnami-images-removed.md)). Five functions in `config/services.yaml` and `resources/components.yaml` read host `postgresql` and Secret `postgresql` / `postgres-password`.

## Root cause

F001. The functions hard-code `user=postgres dbname=postgres` (e.g. `cdevents-endpoint.go`), as c4p does ([F009](F009-c4p-needs-postgres-superuser.md)).

## Evidence

Cluster `pek-ch8`, Knative Serving 1.10.2 + Eventing 1.11.0, 2026-09-30:
- The DORA ksvcs and sockeye became `READY`, and both ApiServerSources were `READY True`.
- After `kubectl apply -f test/example-deployment.yaml`, `cloudevents_raw` had 8 rows and `cdevents_raw` had 1.
- Manually triggered router and frequency jobs completed.
- `curl http://dora-frequency-endpoint.dora-cloudevents.127.0.0.1.sslip.io/deploy-frequency/day` → `[{"DeployName":"nginx-deployment","Deployments":1,"Time":"2026-09-30T00:00:00Z"}]`.

## Fix or workaround

New `resources/postgresql.yaml`: a CNPG `Cluster` `postgresql` in `dora-cloudevents`, with superuser Secret `postgresql-superuser` and `dora-init-sql` run through `postInitSQLRefs`. Both component files now use host `postgresql-rw` and `postgresql-superuser`/`password`. The README installs CNPG and the Cluster.

## How to verify

Follow `chapter-9/dora-cloudevents/README.md` on the chapter-8 Knative cluster.

## Upstream relevance

Yes.
