# F009: c4p-service needs user and database `postgres`, so it uses CloudNativePG's superuser Secret

- **Chapter:** 2, 5, 6
- **Severity:** medium
- **Status:** fixed
- **Fix commit:** 27da304
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

With CNPG's default `<cluster>-app` Secret (user/db `app`), c4p can't connect or find its table.

## Root cause

`c4p-service.go` builds `postgresql://<POSTGRES_USERNAME|postgres>:<pw>@host:5432/postgres?sslmode=disable` (database hard-coded); the chart never sets `POSTGRES_USERNAME`.

## Evidence

`conference-application/c4p-service/c4p-service.go` `NewDB()`.

## Fix or workaround

Chart: `enableSuperuserAccess: true`, `superuserSecret` `<rel>-postgresql-superuser` (`username: postgres`, `password: postgres`), init SQL via `bootstrap.initdb.postInitSQLRefs` (runs as superuser in the `postgres` DB). c4p reads `<rel>-postgresql-superuser` / `password`. Chapter-5 Composition does the same with a CNPG-generated password. Better long-term fix is in code: take the DB name from an env var and use the `-app` Secret.

## How to verify

`kubectl exec conference-postgresql-1 -- psql -U postgres -c '\dt'` lists `proposals`; the e2e flow stores a proposal.

## Upstream relevance

Yes; the code change would let upstream use CNPG's least-privilege `-app` Secret.

