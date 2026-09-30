{{/*
Init container that blocks until each "host:port" in the list accepts TCP connections.
The services exit or panic when Kafka/Redis/PostgreSQL aren't reachable yet, which shows up
as CrashLoopBackOff and RESTARTS while the operators bring the infrastructure up.
Usage: {{ include "conference-app.waitFor" (list "kafka:9092" "redis:6379") }}
*/}}
{{- define "conference-app.waitFor" -}}
initContainers:
- name: wait-for-dependencies
  image: docker.io/library/busybox:1.37
  command:
  - sh
  - -c
  - |
    for target in {{ join " " . }}; do
      host="${target%:*}"; port="${target##*:}"
      until nc -z -w 2 "$host" "$port"; do echo "waiting for $target"; sleep 2; done
      echo "$target is reachable"
    done
{{- end -}}
