# F045: Chapter 9 functions can't be built with current ko (`ko://file.go`)

- **Chapter:** 9
- **Severity:** medium
- **Status:** fixed
- **Fix commit:** f03c06d
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`ko build ./cloudevents-endpoint.go` → `importpath "ko://command-line-arguments" is not supported: importpath is not \`package main\``. `config/services.yaml` uses `ko://cloudevents-endpoint.go` etc.

## Root cause

Each file in `chapter-9/dora-cloudevents/` is its own `package main` in one directory. Older ko accepted a file as the import path, which is where the book's image names come from (`<file>.go-<md5 of file name>`). ko v0.19.1 rejects it.

## Evidence

Publish run 2026-09-30 (log in the clone's `.scratch/publish-main.log`).

## Fix or workaround

`hack/publish-ghcr.sh` copies each file into its own package under `.scratch/dora-build/dora-<fn>/` and runs `ko build --base-import-paths`. The images are `ghcr.io/allensanborn/dora-<fn>:v1.2.0`, and `resources/components.yaml` uses them. `config/services.yaml` (the `ko apply` dev path) still has the `ko://file.go` references and won't build with current ko; the proper fix is a `cmd/<fn>/main.go` layout (not done).

## How to verify

The chapter-9 DORA flow with `resources/components.yaml`.

## Upstream relevance

Yes.
