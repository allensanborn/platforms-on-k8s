# F050: Removed the dead `keptn.sh/post-deployment-tasks` labels from the Conference charts

- **Chapter:** 2, 7, 9
- **Severity:** low
- **Status:** fixed
- **Fix commit:** PENDING
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

Every service Deployment's pod template carried `keptn.sh/post-deployment-tasks: stdout-notification`, a Keptn Lifecycle Toolkit marker.

## Root cause

Keptn is being replaced in chapter 9. See finding F061 on branch `keptn-current`: the chapter is rebuilt on Argo CD metrics, Jaeger v2, a PostSync hook and Argo Rollouts analysis.

## Evidence

`grep -rn keptn conference-application/helm` on both branches before the change: 4 templates each.

## Fix or workaround

Removed from `conference-app` v1.2.0 (main line) and v2.1.0 (Dapr branch) before either was published. `chapter-4/argo-cd/staging-kube/app.yaml` was regenerated. The published v1.1.0 still has the labels, which are harmless without Keptn.

## How to verify

`helm template t oci://ghcr.io/allensanborn/conference-app --version v1.2.0 | grep -c keptn` → 0.

## Upstream relevance

Yes, with the Keptn replacement.
