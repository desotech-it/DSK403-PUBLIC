#!/usr/bin/env bash
# Q02 fix: aggiunge --anonymous-auth=false al manifest statico di kube-apiserver.
set -uo pipefail
CTL="${CTL:-dsk102-lab-08-control-plane}"

if ! docker ps --format '{{.Names}}' | grep -q "^${CTL}$"; then
  echo "⚠️  Container '${CTL}' non trovato. Imposta CTL=<nome-control-plane-container> e rilancia."
  exit 1
fi

# Idempotente: rimuovi qualunque --anonymous-auth=… esistente, poi aggiungi false
docker exec "$CTL" sed -i '\|--anonymous-auth=|d' /etc/kubernetes/manifests/kube-apiserver.yaml
docker exec "$CTL" sed -i '/- kube-apiserver/a\    - --anonymous-auth=false' /etc/kubernetes/manifests/kube-apiserver.yaml

echo "Attendo il restart del pod statico (~30s)..."
sleep 30

APISERVER="https://$(kubectl get endpoints kubernetes -o jsonpath='{.subsets[0].addresses[0].ip}'):6443"
echo "Test anonimo verso $APISERVER (atteso 401):"
curl -k -s -o /dev/null -w "HTTP %{http_code}\n" "$APISERVER/api/v1/namespaces"
echo
echo "✅ Fix applicata."
