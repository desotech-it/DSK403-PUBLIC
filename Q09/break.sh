#!/usr/bin/env bash
# Q09 break: ns nonroot (PSA restricted) + Pod nginx come UID 1000 senza NET_BIND_SERVICE -> CrashLoopBackOff
set -euo pipefail
F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
apiVersion: v1
kind: Namespace
metadata:
  name: nonroot
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  namespace: nonroot
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    seccompProfile: { type: RuntimeDefault }
  containers:
  - name: nginx
    image: nginx:1.27
    ports: [ { containerPort: 80 } ]
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
YAML
kubectl delete pod nginx -n nonroot --ignore-not-found
kubectl apply -f "$F"
rm -f "$F"
sleep 5

echo
echo "✅ Stato 'rotto' applicato (atteso: CrashLoopBackOff, nginx non riesce a legare :80):"
echo "   kubectl -n nonroot get pod nginx"
echo "   kubectl -n nonroot logs nginx --tail=5"
