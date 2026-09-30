# F015: `exportKubeConfig.server: https://<name>.<ns>.svc` fails TLS verification

- **Chapter:** 6
- **Severity:** high
- **Status:** fixed
- **Fix commit:** b2ee1fc
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

provider-helm: `kubernetes cluster unreachable: Get "https://team-a-dev-env.team-a.svc:443/version": tls: failed to verify certificate: x509: certificate is valid for kubernetes.default.svc.cluster.local, kubernetes.default.svc, kubernetes.default, kubernetes, localhost, *.nodes.vcluster.com, *.team-a-dev-env.team-a.nodes.vcluster.com, my-host.com, team-a-dev-env, team-a-dev-env.team-a, not team-a-dev-env.team-a.svc`.

## Root cause

vcluster 0.37.2's serving certificate lists `<name>` and `<name>.<namespace>` but not `<name>.<namespace>.svc`.

## Evidence

Above error, 2026-09-30, `pek-ch5`.

## Fix or workaround

Composition sets `https://<name>.<namespace>:443` (resolves through the pod's search domains). No `insecure`, CA or extra SANs needed. (`controlPlane.proxy.extraSANs` would be the alternative; not tried.)

## How to verify

`kubectl get releases.helm.m.crossplane.io -n team-a` — all `SYNCED True READY True`.

## Upstream relevance

Yes; also corrects the wiki's v2 edition page.

