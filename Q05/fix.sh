#!/usr/bin/env bash
# Q05 fix: copia il profilo su tutti i worker node (container kind) e lo carica con apparmor_parser.
set -euo pipefail
PROFILE=/tmp/k8s-deny-write
if [[ ! -f "$PROFILE" ]]; then
  echo "⚠️  $PROFILE non esiste. Esegui prima break.sh."
  exit 1
fi

# Trova i nodi worker del cluster kind
NODES=$(docker ps --format '{{.Names}}' | grep -E 'worker' || true)
if [[ -z "$NODES" ]]; then
  echo "⚠️  Nessun nodo worker kind trovato. Imposta NODES=... e rilancia manualmente."
  exit 1
fi

for N in $NODES; do
  echo "--- carico profilo su $N ---"
  docker cp "$PROFILE" "$N":/etc/apparmor.d/k8s-deny-write
  docker exec "$N" apparmor_parser -q -r /etc/apparmor.d/k8s-deny-write
  docker exec "$N" aa-status 2>/dev/null | grep -E 'k8s-deny-write' || true
done

# Ricicla il pod (il fallimento iniziale è sticky)
kubectl delete pod secure-app --ignore-not-found
F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
spec:
  securityContext:
    appArmorProfile:
      type: Localhost
      localhostProfile: k8s-deny-write
  containers:
  - name: app
    image: alpine:3.20
    command: ["sh", "-c", "sleep 36000"]
YAML
kubectl apply -f "$F"
rm -f "$F"
kubectl wait --for=condition=Ready pod/secure-app --timeout=60s

echo
echo "✅ Fix applicata. Verifica:"
echo "   kubectl exec secure-app -- sh -c 'touch /tmp/x'  # deve fallire (Permission denied)"
