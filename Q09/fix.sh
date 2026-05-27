#!/usr/bin/env bash
# Q09 fix: ricrea il pod nginx come UID 1000 + capability NET_BIND_SERVICE +
# emptyDir per i path che nginx scrive (pid, cache, log).
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
    fsGroup: 1000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: nginx
    image: nginx:1.27
    ports:
    - containerPort: 80
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop: ["ALL"]
        add: ["NET_BIND_SERVICE"]
    volumeMounts:
    - { name: var-run,         mountPath: /var/run }
    - { name: var-cache-nginx, mountPath: /var/cache/nginx }
    - { name: var-log-nginx,   mountPath: /var/log/nginx }
  volumes:
  - { name: var-run,         emptyDir: {} }
  - { name: var-cache-nginx, emptyDir: {} }
  - { name: var-log-nginx,   emptyDir: {} }
YAML
kubectl apply -f "$F"
rm -f "$F"
kubectl -n nonroot wait --for=condition=Ready pod/nginx --timeout=90s

echo
echo "✅ Fix applicata. Verifica:"
echo "   kubectl -n nonroot exec nginx -- ss -tln | head"
echo "   kubectl -n nonroot exec nginx -- id -u"
