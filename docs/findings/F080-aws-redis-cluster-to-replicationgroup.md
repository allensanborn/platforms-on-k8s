# F080: AWS Redis Composition used an ElastiCache `Cluster`, which Floci rejects and whose address the provider never publishes

- **Chapter:** 5 (aws)
- **Severity:** high
- **Status:** fixed (tested against Floci 2.1.0, not a real AWS account)
- **Fix commit:** dfa2ca7
- **Found:** 2026-09-30, branch `aws-floci`

## Symptom

Against Floci 2.1.0 the `elasticache.aws.m.upbound.io/v1beta1 Cluster` with `engine: redis` never got Ready:

```
create failed: async create failed: ... operation error ElastiCache: CreateCacheCluster, https response error StatusCode: 400, ... InvalidParameterValue: Engine must be 'memcached'. For Redis/Valkey use CreateReplicationGroup.
```

## Root cause

Two separate problems with the same fix.

1. Floci (divergence from AWS): `ElastiCacheQueryHandler.handleCreateCacheCluster` (Floci tag 2.1.0) refuses every engine except memcached. Real AWS accepts a single-node Redis `CreateCacheCluster`.
2. Real AWS (from provider source, not observed on an account): provider-upjet-aws v2.8.1 `config/namespaced/elasticache/config.go` sets the `aws_elasticache_cluster` connection details from `cluster_address` and `port` with the comment `// This only works for memcached clusters`. Taken at its word, for Redis the connection Secret would hold only `port`, with no host to give the app. UNVERIFIED: the terraform-provider-aws side (when `cluster_address` is set) was not read, and this was not run against AWS.

## Evidence

The MR's conditions with the 400 above (run on kind `pek-floci`, Crossplane v2.4.2, provider family v2.8.1). The `aws_elasticache_replication_group` configurator in the same provider file publishes `primary_endpoint_address`, `configuration_endpoint_address`, `reader_endpoint_address` and `port`. After the switch the Database XR was Ready on Floci and the connection Secret held an endpoint address and `port: 6379`.

## Fix or workaround

`chapter-5/aws/resources/app-database-redis.yaml` now composes `elasticache.aws.m.upbound.io/v1beta1 ReplicationGroup` (`description`, `engine: redis`, `nodeType: cache.t3.micro`, `numCacheClusters: 1`). A ReplicationGroup is also what AWS recommends for Redis/Valkey. The README reads the host as `{.status.atProvider.primaryEndpointAddress}{.status.atProvider.configurationEndpointAddress}`, because Floci fills the second where AWS fills the first (see F083).

## How to verify

Run `chapter-5/aws/README.md` against Floci: `kubectl get dbs -n team-a` shows `aws-db-keyvalue` READY True.

## Upstream relevance

Yes.
