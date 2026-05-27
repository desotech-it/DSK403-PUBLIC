#!/usr/bin/env bash
# Q09 fix: ricrea il Pod con la capability NET_BIND_SERVICE aggiunta
set -euo pipefail
kubectl delete pod nginx -n nonroot --ignore-not-found

F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
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
        add:  ["NET_BIND_SERVICE"]
YAML
kubectl apply -f "$F"
rm -f "$F"
kubectl -n nonroot wait --for=condition=Ready pod/nginx --timeout=60s

echo
echo "✅ Fix applicata. Verifica:"
echo "   kubectl -n nonroot exec nginx -- ss -tln | head"
echo "   kubectl -n nonroot exec nginx -- id -u"
