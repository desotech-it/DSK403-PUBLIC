#!/usr/bin/env bash
# Q04 break: ns prod + SA app-sa (automount=false) + Pod app con automount=true (override)
set -euo pipefail
kubectl create namespace prod --dry-run=client -o yaml | kubectl apply -f -

F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: prod
automountServiceAccountToken: false
---
apiVersion: v1
kind: Pod
metadata:
  name: app
  namespace: prod
spec:
  serviceAccountName: app-sa
  automountServiceAccountToken: true
  containers:
  - name: app
    image: alpine:3.20
    command: ["sleep", "36000"]
YAML
kubectl delete pod app -n prod --ignore-not-found
kubectl apply -f "$F"
rm -f "$F"
kubectl -n prod wait --for=condition=Ready pod/app --timeout=60s

echo
echo "✅ Stato 'rotto' applicato. Conferma (atteso: token presente):"
echo "   kubectl -n prod exec app -- ls /var/run/secrets/kubernetes.io/serviceaccount/"
