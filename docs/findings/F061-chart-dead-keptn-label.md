# F061: The Conference chart still puts a dead `keptn.sh/post-deployment-tasks` label on every service

- **Chapter:** 2-9 (chart), 9 (keptn)
- **Severity:** low
- **Status:** open (chart change routed to the chart's owner; not changed on `keptn-current`)
- **Fix commit:** —
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

Every service's pod template carries a Keptn label that nothing reads any more:

```
conference-application/helm/conference-app/templates/agenda-service.yaml:17:        keptn.sh/post-deployment-tasks: stdout-notification
conference-application/helm/conference-app/templates/c4p-service.yaml:17:        keptn.sh/post-deployment-tasks: stdout-notification
conference-application/helm/conference-app/templates/frontend.yaml:17:        keptn.sh/post-deployment-tasks: stdout-notification
conference-application/helm/conference-app/templates/notifications-service.yaml:17:        keptn.sh/post-deployment-tasks: stdout-notification
```

It sits under `spec.template.metadata.labels`, although the book and the old tutorial call it an annotation.

## Root cause

Keptn is archived ([F060](F060-keptn-archived-tutorial-replaced.md)), and the chapter-9 tutorial no longer installs it. The label does nothing, but readers will look for what uses it.

## Fix or workaround

Delete those four lines in the chart (and republish). Keep the `app.kubernetes.io/name`, `part-of` and `version` labels: they are standard, and the new post-sync task prints `version`.

## How to verify

`git grep keptn -- conference-application` returns nothing.

## Upstream relevance

Yes.
