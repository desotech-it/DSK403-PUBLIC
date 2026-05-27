#!/usr/bin/env bash
# Q06 break: Pod 'risky' con seccompProfile RuntimeDefault ma privileged:true (sovrascrive seccomp)
set -euo pipefail
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
  containers:
  - name: c
    image: alpine:3.20
    command: ["sleep", "36000"]
    securityContext:
      privileged: true
YAML
kubectl delete pod risky --ignore-not-found
kubectl apply -f "$F"
rm -f "$F"
kubectl wait --for=condition=Ready pod/risky --timeout=60s

echo
echo "✅ Stato 'rotto' applicato. Conferma (atteso: Seccomp: 0 = unconfined):"
echo "   kubectl exec risky -- grep ^Seccomp /proc/1/status"
