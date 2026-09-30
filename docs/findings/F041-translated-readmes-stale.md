# F041: Translated READMEs still carry the old commands

- **Chapter:** 2, 4, 5, 6, 7, 8, 9
- **Severity:** low
- **Status:** open
- **Fix commit:** —
- **Found:** 2026-09-30, branch `crossplane-v2-and-bitnami-replacements`

## Symptom

`README-es.md`, `README-ja.md`, `README-zh.md`, `README-pt.md` and `README-fr.md` in the touched chapters still install Bitnami charts and the Docker Hub `conference-app:v1.0.0`, and they show Crossplane v1 YAML.

## Root cause

Only the English READMEs were updated here.

## Evidence

`grep -rl bitnami --include='README-*.md' .`

## Fix or workaround

None. Readers should follow the English README, which is the tested one.

## How to verify

As in Evidence.

## Upstream relevance

Yes, for translators once the English versions settle.
