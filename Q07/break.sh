#!/usr/bin/env bash
# Q07 break: ns prod con PSA restricted + Deployment 'bad-app' non conforme
set -euo pipefail
F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: latest
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/warn: restricted
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bad-app
  namespace: prod
spec:
  replicas: 3
  selector: { matchLabels: { app: bad } }
  template:
    metadata: { labels: { app: bad } }
    spec:
      containers:
      - name: app
        image: nginx:1.27
        securityContext:
          runAsUser: 0
      volumes:
      - name: host
        hostPath: { path: /tmp, type: Directory }
YAML
kubectl apply -f "$F"
rm -f "$F"
sleep 3

echo
echo "✅ Stato 'rotto' applicato. Conferma (atteso: 0/3 ready, FailedCreate sul RS):"
echo "   kubectl -n prod get deploy bad-app"
echo "   kubectl -n prod describe rs -l app=bad | tail -20"
