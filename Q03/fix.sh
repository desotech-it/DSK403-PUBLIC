#!/usr/bin/env bash
# Q03 fix: ricrea il RoleBinding con il nome utente OIDC completo
set -euo pipefail

F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-read
  namespace: dev
subjects:
- kind: User
  name: oidc:alice@example.com
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: view
  apiGroup: rbac.authorization.k8s.io
YAML
kubectl apply -f "$F"
rm -f "$F"

echo
echo "✅ Fix applicata. Verifica:"
echo "   kubectl auth can-i get pods -n dev --as=oidc:alice@example.com   # yes"
echo "   kubectl auth can-i delete pods -n dev --as=oidc:alice@example.com # no (read-only)"
