# F084: With a real AWS account, a local kind cluster can't reach the RDS, ElastiCache or MSK endpoints

- **Chapter:** 5 (aws)
- **Severity:** medium
- **Status:** documented
- **Fix commit:** see README row
- **Found:** 2026-09-30, branch `aws-floci`

## Symptom

The tutorial installs the Conference app into the same local kind cluster that runs Crossplane, then points it at the AWS endpoints.

## Root cause

The Compositions create RDS (not publicly accessible), ElastiCache and MSK in a VPC. ElastiCache and MSK have no public endpoints in this configuration at all, so a laptop cluster cannot connect without a VPN or tunnel into the VPC.

## Evidence

AWS service behaviour; not tested against an account. Against Floci the endpoints are local containers, so the issue does not show up there (F083).

## Fix or workaround

The README warning says the app must run somewhere that can reach the VPC (for example EKS in that VPC). Crossplane itself can still run on kind, since it only calls AWS APIs.

## How to verify

n/a without an AWS account.

## Upstream relevance

Yes (README note).
