# F004: ingress-nginx's kind manifest no longer pins the controller to the `ingress-ready` node

- **Chapter:** 2 (and every chapter reusing its cluster)
- **Severity:** medium
- **Status:** fixed
- **Fix commit:** 27da304
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`curl http://localhost/` → `Recv failure: Connection reset by peer` although the Ingress exists and shows `ADDRESS localhost`.

## Root cause

The chapter applies `deploy/static/provider/kind/deploy.yaml` from ingress-nginx `main`. That manifest (controller v1.15.1 on 2026-09-30) has `nodeSelector: {kubernetes.io/os: linux}` only; it tolerates the control-plane taint but no longer selects `ingress-ready=true`. With the chapter's 1 control plane + 3 workers the controller landed on `pek-ch2-worker`, while kind maps host ports 80/443 only to the control-plane container.

## Evidence

`kubectl get deploy -n ingress-nginx ingress-nginx-controller -o jsonpath='{.spec.template.spec.nodeSelector}'` → `{"kubernetes.io/os":"linux"}`; controller pod on `pek-ch2-worker`; `docker port pek-ch2-control-plane` → `80/tcp -> 0.0.0.0:80`.

## Fix or workaround

README adds `kubectl patch deploy -n ingress-nginx ingress-nginx-controller -p '{"spec":{"template":{"spec":{"nodeSelector":{"ingress-ready":"true"}}}}}'`. After the patch `curl http://localhost/` returned 200.

## How to verify

`kubectl get pods -n ingress-nginx -o wide` shows the controller on the control-plane node; `curl -s -o /dev/null -w '%{http_code}' http://localhost/` → 200.

## Upstream relevance

Yes. Also consider pinning a controller release instead of `main`; ingress-nginx's retirement was announced (not verified here, see [F031](F031-tool-version-drift.md)).

