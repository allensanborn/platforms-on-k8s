# F028: v2 edition page: composed CNPG `-app` Secret and no init SQL

- **Chapter:** 5
- **Severity:** medium
- **Status:** documented (page) / fixed (repo)
- **Fix commit:** 7d71eb2
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

The wiki's v2 edition page wires C4P to `my-db-sql-postgresql-app` and its SQL Composition has no init SQL.

## Root cause

See F009: c4p needs `postgres`/`postgres`; the `proposals` table must be created.

## Evidence

Tested alternative passes e2e.

## Fix or workaround

Repo Composition: `enableSuperuserAccess: true`, `postInitSQLRefs` → `c4p-init-sql` in the XR namespace; app reads `<xr>-postgresql-superuser` / `password`.

## How to verify

Chapter-5 README flow.

## Upstream relevance

No (wiki-side).

