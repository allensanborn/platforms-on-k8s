# F083: The chapter-5 AWS tutorial runs end to end against Floci 2.1.0, with a Floci-only ProviderConfig overlay

- **Chapter:** 5 (aws)
- **Severity:** info
- **Status:** documented (README section "Running against Floci", overlay `chapter-5/aws/floci/providerconfig.yaml`)
- **Fix commit:** dfa2ca7
- **Found:** 2026-09-30, branch `aws-floci`

## Symptom

The AWS Compositions had only been schema-checked (F022). There was no way to run them without an AWS account.

## Root cause

n/a. This records how the tutorial was run against [Floci](https://github.com/floci-io/floci) 2.1.0 (`floci/floci:2.1.0`) and where Floci differed from AWS.

## Evidence

kind cluster on Docker's `kind` network, Crossplane v2.4.2, function-patch-and-transform v0.11.0, provider-aws-{ec2,elasticache,kafka,rds} v2.8.1, chart `oci://ghcr.io/allensanborn/conference-app` v1.1.0 (digest `sha256:a7e7b8e3…`). Run twice, the second time following the README commands as written. Both times: VPC, Subnets and SG Ready, then the Database (sql, keyvalue) and MessageBroker XRs Ready (about 2 minutes the first time; 8 minutes the second, with another kind cluster competing for CPU). Both init Jobs Complete, all four services Available with 0 restarts, and the e2e flow passed: a proposal submitted and approved, an agenda item created, a notification sent, and 4 events (`new-proposal`, `new-agenda-item`, `proposal-approved`, `notification-sent`) on `events-topic` (Redpanda high watermark 4). On delete, every managed resource went away and Floci removed its PostgreSQL, Valkey and Redpanda containers and volumes.

Wiring that made it work:

- `endpoint.services` in the ClusterProviderConfig is required. provider-upjet-aws v2.8.1 `internal/clients/aws.go` (`configureNoForkAWSClient`) copies the static URL only into the endpoint map entries named there; any service not listed is sent to real AWS. The overlay lists `ec2, elasticache, kafka, rds, sts`, with `skip_credentials_validation`, `skip_metadata_api_check`, `skip_region_validation` and `skip_requesting_account_id`.
- Networking: Floci runs on the `kind` network. kind's node entrypoint (`enable_network_magic`) forwards pod DNS to Docker's embedded DNS, so pods resolve `floci` and the Redpanda container names. That matters because a containerised Floci starts Redpanda with `--advertise-kafka-addr <container-name>:9092` and reports the bootstrap as the container IP.
- Ports: the chart has no port values and c4p-service defaults to 5432. `FLOCI_SERVICES_RDS_PROXY_BASE_PORT=5432` plus `FLOCI_SERVICES_RDS_ENDPOINT_HOST=floci` make the RDS instance report `floci:5432`; `FLOCI_HOSTNAME=floci` makes ElastiCache report `floci:6379`. Plain (non-TLS) PostgreSQL through Floci's RDS proxy worked.

## Floci divergences seen (Floci 2.1.0 vs AWS as documented)

1. `CreateCacheCluster` rejects `Engine=redis` (F080). AWS accepts it.
2. `DescribeReplicationGroups` for a group with `ClusterEnabled=false` returns a `ConfigurationEndpoint` as well as the node group's `PrimaryEndpoint`. AWS documents the configuration endpoint for cluster-mode-enabled groups only. As a result the provider's `primaryEndpointAddress` stayed empty and `configurationEndpointAddress` was `floci`. (Raw XML captured during the run.)
3. MSK `numberOfBrokerNodes: 2` produced one Redpanda container. The bootstrap string lists one broker.
4. Redpanda's `auto_create_topics_enabled` was `true`. MSK's default configuration has `auto.create.topics.enable=false`.
5. Deleting the Subnets and SecurityGroup while the MSK cluster still existed succeeded. On AWS, ENIs of a running MSK cluster would block that.

## Fix or workaround

README section "Running against Floci"; `floci/providerconfig.yaml` replaces the AWS Secret and ClusterProviderConfig and is the only Floci-specific file. Everything else is the same for a real account.

## How to verify

Follow `chapter-5/aws/README.md` with the Floci section.

## Upstream relevance

Optional (useful for readers without an AWS account).
