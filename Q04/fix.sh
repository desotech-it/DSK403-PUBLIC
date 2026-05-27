#!/usr/bin/env bash
# Q04 fix: ricrea il Pod con automountServiceAccountToken=false a livello pod
set -euo pipefail
kubectl delete pod app -n prod --ignore-not-found

F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
apiVersion: v1
kind: Pod
metadata:
  name: app
  namespace: prod
spec:
  serviceAccountName: app-sa
  automountServiceAccountToken: false
  containers:
  - name: app
    image: alpine:3.20
    command: ["sleep", "36000"]
YAML
kubectl apply -f "$F"
rm -f "$F"
kubectl -n prod wait --for=condition=Ready pod/app --timeout=60s

echo
echo "✅ Fix applicata. Verifica:"
echo "   kubectl -n prod exec app -- ls /var/run/secrets/kubernetes.io/serviceaccount/"
echo "   (atteso: 'No such file or directory')"
