#!/usr/bin/env bash
# Q07 fix: sostituisce il Deployment con uno conforme a PSA restricted (nginx-unprivileged + emptyDir + securityContext stretti)
set -euo pipefail
F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
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
      securityContext:
        runAsNonRoot: true
        runAsUser: 10001
        seccompProfile: { type: RuntimeDefault }
      containers:
      - name: app
        image: nginxinc/nginx-unprivileged:1.27
        ports: [ { containerPort: 8080 } ]
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities: { drop: ["ALL"] }
        volumeMounts:
        - { name: cache, mountPath: /var/cache/nginx }
        - { name: tmp,   mountPath: /tmp }
        - { name: run,   mountPath: /var/run }
      volumes:
      - { name: cache, emptyDir: {} }
      - { name: tmp,   emptyDir: {} }
      - { name: run,   emptyDir: {} }
YAML
kubectl apply -f "$F"
rm -f "$F"
kubectl -n prod rollout status deploy/bad-app --timeout=120s

echo
echo "✅ Fix applicata. Verifica:"
echo "   kubectl -n prod get deploy,pod -l app=bad"
