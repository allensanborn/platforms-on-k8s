# F081: The MSK Composition's subnet and security-group selectors had nothing to select

- **Chapter:** 5 (aws)
- **Severity:** high
- **Status:** fixed (tested against Floci 2.1.0, not a real AWS account)
- **Fix commit:** dfa2ca7
- **Found:** 2026-09-30, branch `aws-floci`

## Symptom

F022 added `clientSubnetsSelector` and `securityGroupsSelector` (label `platform.salaboy.com/msk: "true"`) to the MSK Cluster and told the reader to "create or label them yourself". Those selectors resolve against `ec2.aws.m.upbound.io` Subnet and SecurityGroup managed resources, but `providers.yaml` didn't install provider-aws-ec2 and the chapter shipped no such resources. The MSK Cluster could not resolve its references.

## Root cause

terraform-provider-aws's `aws_msk_cluster` needs `client_subnets` and `security_groups`, and upjet resolves selectors only against MRs in the same namespace.

## Evidence

On Floci, after adding the provider and the resources: VPC, two Subnets and a SecurityGroup were Ready, the MSK Cluster resolved `clientSubnets: [subnet-23d7c725, subnet-e1c61494]` and became Ready, and `crossplane resource validate` passed for all four against the installed v2.8.1 CRDs.

## Fix or workaround

`providers.yaml` adds `provider-aws-ec2:v2.8.1`. New `chapter-5/aws/network.yaml` creates a VPC (10.20.0.0/16), Subnets in us-west-2a and us-west-2b and a SecurityGroup in `team-a`, all labelled. On a real account it creates a new VPC; the README says to edit the AZs or import and label existing subnets instead. Delete it only after the MSK cluster is gone.

## How to verify

`kubectl wait vpc,subnet,securitygroup -n team-a --all --for=condition=Ready`, then `kubectl get mbs -n team-a` READY True.

## Upstream relevance

Yes.
