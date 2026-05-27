#!/usr/bin/env bash
# Q03 break: ns dev + RoleBinding con subject SENZA prefisso oidc:
set -euo pipefail
kubectl create namespace dev --dry-run=client -o yaml | kubectl apply -f -

F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-read
  namespace: dev
subjects:
- kind: User
  name: alice@example.com
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
YAML
kubectl apply -f "$F"
rm -f "$F"

echo
echo "✅ Stato 'rotto' applicato. Conferma:"
echo "   kubectl auth can-i get pods -n dev --as=oidc:alice@example.com   # no"
