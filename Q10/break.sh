#!/usr/bin/env bash
# Q10 break: deploya un finto image-scanner webhook (al momento NON attivato come admission).
set -euo pipefail
F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
apiVersion: v1
kind: Service
metadata:
  name: image-scanner
  namespace: default
spec:
  selector: { app: image-scanner }
  ports:
  - { port: 443, targetPort: 8443 }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: image-scanner
  namespace: default
spec:
  replicas: 1
  selector: { matchLabels: { app: image-scanner } }
  template:
    metadata: { labels: { app: image-scanner } }
    spec:
      containers:
      - name: scanner
        image: nginxinc/nginx-unprivileged:1.27
        ports: [{ containerPort: 8443 }]
YAML
kubectl apply -f "$F"
rm -f "$F"

echo
echo "✅ Stato 'rotto' applicato (atteso: admission NON blocca):"
echo "   kubectl run pre-test --image=registry.example.com/bad-image:1.0 --dry-run=server"
