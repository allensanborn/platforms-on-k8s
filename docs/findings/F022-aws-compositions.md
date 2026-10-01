# F022: AWS compositions used an archived provider and an incomplete MSK spec

- **Chapter:** 5 (aws)
- **Severity:** medium
- **Status:** fixed (run end to end against Floci 2.1.0, see F080-F083; not against a real AWS account)
- **Fix commit:** 12e796d
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

The original used `crossplane/provider-aws:v0.21.2` (community, archived) resources with an `aws.upbound.io` ProviderConfig, and an MSK Cluster without subnets or security groups.

## Root cause

Written before the Upbound provider family and Crossplane v2.

## Evidence

Schema check: `crossplane render` of each XR piped to `crossplane resource validate` against provider-upjet-aws v2.8.1 CRDs → all three MRs `validated successfully`.

## Fix or workaround

Pipeline Compositions over namespaced `elasticache.aws.m.upbound.io/v1beta1 Cluster`, `rds.aws.m.upbound.io/v1beta1 Instance` (user `postgres`, generated password Secret), `kafka.aws.m.upbound.io/v1beta1 Cluster` (subnets/SGs by label); `providers.yaml`; `aws.m.upbound.io/v1beta1 ClusterProviderConfig`. Connection Secret keys unverified.

## How to verify

Run `chapter-5/aws/README.md` against Floci (done, F083) or an AWS account (not done).

## Upstream relevance

Yes.

