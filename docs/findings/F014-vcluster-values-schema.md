# F014: vcluster 0.15.7 values (`syncer.extraArgs`, `multiNamespaceMode`, `fallbackHostDns`) are obsolete

- **Chapter:** 6
- **Severity:** high
- **Status:** fixed
- **Fix commit:** b2ee1fc
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

The chapter-6 Composition pins vcluster 0.15.7 with pre-0.20 values; kubeconfig export flags (`--out-kube-config-secret`, `--out-kube-config-server`, `--tls-san`) no longer exist.

## Root cause

vcluster 0.20 replaced the values schema.

## Evidence

`helm show values vcluster --repo https://charts.loft.sh --version 0.37.2`: `exportKubeConfig.server`, `.insecure`, `.secret` (deprecated), `.additionalSecrets`.

## Fix or workaround

vcluster 0.37.2 with only `exportKubeConfig.server` set; vcluster writes the kubeconfig to Secret `vc-<name>` key `config` (it also creates `vc-config-<name>`, its own config).

## How to verify

`kubectl get secret -n team-a vc-team-a-dev-env`.

## Upstream relevance

High.

