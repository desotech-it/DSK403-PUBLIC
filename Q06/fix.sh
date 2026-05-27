#!/usr/bin/env bash
# Q06 fix: ricrea il Pod senza privileged, con drop:[ALL] e seccomp RuntimeDefault
set -euo pipefail
kubectl delete pod risky --ignore-not-found
F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
apiVersion: v1
kind: Pod
metadata:
  name: risky
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault
    runAsNonRoot: true
    runAsUser: 1000
  containers:
  - name: c
    image: alpine:3.20
    command: ["sleep", "36000"]
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
YAML
kubectl apply -f "$F"
rm -f "$F"
kubectl wait --for=condition=Ready pod/risky --timeout=60s

echo
echo "✅ Fix applicata. Verifica (atteso: Seccomp: 2 = filtered):"
echo "   kubectl exec risky -- grep ^Seccomp /proc/1/status"
