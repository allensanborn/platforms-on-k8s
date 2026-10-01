# F082: On the AWS path nothing created `events-topic` or the `proposals` table

- **Chapter:** 5 (aws)
- **Severity:** high
- **Status:** fixed (tested against Floci 2.1.0, not a real AWS account)
- **Fix commit:** dfa2ca7
- **Found:** 2026-09-30, branch `aws-floci`

## Symptom

The local Compositions get the topic from a composed Strimzi `KafkaTopic` and the table from CloudNativePG's init SQL. The AWS path had neither: `resources/c4p-sql-init.yaml` was a ConfigMap with no namespace (it landed in `default`) and nothing consumed it; c4p-service never creates its table, and every service dials `events-topic` with `kafka.DialLeader`.

## Root cause

RDS and MSK start empty. MSK's default broker configuration has `auto.create.topics.enable=false` (AWS documentation; not checked on an account), so the topic doesn't appear on first use either.

## Evidence

With the fix, on Floci: Job `c4p-init-sql` logged `CREATE TABLE`, Job `events-topic` logged `Created topic events-topic.`, and the e2e flow then passed (F083).

## Fix or workaround

New `chapter-5/aws/init-jobs.yaml`: the ConfigMap (now in `team-a`, `CREATE TABLE IF NOT EXISTS`), a `postgres:17-alpine` Job that runs it with host, port and user from the `aws-db-sql-postgres-connection` Secret and the password from `aws-db-sql-postgres-password`, and an `apache/kafka:3.9.1` Job running `kafka-topics.sh --create --if-not-exists` against the bootstrap string from an `aws-endpoints` ConfigMap the README creates. `resources/c4p-sql-init.yaml` removed.

## How to verify

`kubectl wait job --all -n team-a --for=condition=Complete`.

## Upstream relevance

Yes.
