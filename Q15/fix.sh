#!/usr/bin/env bash
# Q15 fix: crea RuntimeClass gvisor + Kyverno mutate che la inietta nei pod del namespace tenants-untrusted.
set -euo pipefail

F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
apiVersion: node.k8s.io/v1
kind: RuntimeClass
metadata:
  name: gvisor
handler: runsc
---
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: set-gvisor-on-untrusted
spec:
  rules:
  - name: add-runtimeclass
    match:
      any:
      - resources:
          kinds: [Pod]
          namespaces: [tenants-untrusted]
    mutate:
      patchStrategicMerge:
        spec:
          runtimeClassName: gvisor
YAML
kubectl apply -f "$F"
rm -f "$F"

echo
echo "✅ Fix applicata. Verifica:"
echo "   kubectl delete pod probe -n tenants-untrusted --ignore-not-found"
echo "   kubectl run probe -n tenants-untrusted --image=alpine:3.20 -- sleep 60"
echo "   kubectl -n tenants-untrusted get pod probe -o jsonpath='{.spec.runtimeClassName}'"
echo "   (atteso: gvisor)"
