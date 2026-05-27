#!/usr/bin/env bash
# Q01 break: ns prod + pod test + NetworkPolicy default-deny
set -euo pipefail
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -
kubectl -n prod run test --image=curlimages/curl:8.10.1 --restart=Never --command -- sleep 36000 2>/dev/null || true
kubectl -n prod wait --for=condition=Ready pod/test --timeout=60s

F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
  namespace: prod
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
YAML
kubectl apply -f "$F"
rm -f "$F"

echo
echo "✅ Stato 'rotto' applicato. Verifica:"
echo "   kubectl -n prod exec test -- nslookup kubernetes.io      # deve fallire"
echo "   kubectl -n prod exec test -- curl -m 5 https://kubernetes.io   # deve fallire"
