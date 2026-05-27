#!/usr/bin/env bash
# Q14 fix: aggiunge la rule custom 'Shell in container' come ConfigMap montato.
set -euo pipefail

F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
apiVersion: v1
kind: ConfigMap
metadata:
  name: falco-custom-rules
  namespace: falco
data:
  custom-shell.yaml: |
    - rule: Shell in container (custom)
      desc: Allerta quando una shell interattiva è eseguita dentro un container.
      condition: >
        spawned_process
        and container
        and shell_procs
        and proc.tty != 0
      output: >
        Shell spawned in container
        (user=%user.name shell=%proc.name pid=%proc.pid
         image=%container.image.repository
         pod=%k8s.pod.name ns=%k8s.ns.name)
      priority: NOTICE
      tags: [container, shell, mitre_execution]
YAML
kubectl apply -f "$F"
rm -f "$F"

# Patcha il DaemonSet via Helm reuse-values
helm upgrade falco falcosecurity/falco -n falco --reuse-values \
  --set-json 'extraVolumes=[{"name":"custom-rules","configMap":{"name":"falco-custom-rules"}}]' \
  --set-json 'extraVolumeMounts=[{"name":"custom-rules","mountPath":"/etc/falco/rules.d","readOnly":true}]' \
  >/dev/null

kubectl -n falco rollout status ds/falco

echo
echo "✅ Fix applicata. Trigger e verifica:"
echo "   kubectl run target --image=alpine:3.20 -- sleep 3600"
echo "   kubectl wait --for=condition=Ready pod/target --timeout=60s"
echo "   kubectl exec -it target -- sh -c 'echo hello from shell'"
echo "   sleep 3 && kubectl -n falco logs ds/falco --tail=200 | grep 'Shell spawned'"
