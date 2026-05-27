#!/usr/bin/env bash
# Q02 fix: aggiunge --anonymous-auth=false al manifest statico di kube-apiserver.
set -uo pipefail
CTL="${CTL:-dsk102-lab-08-control-plane}"

if ! docker ps --format '{{.Names}}' | grep -q "^${CTL}$"; then
  echo "⚠️  Container '${CTL}' non trovato. Imposta CTL=<nome-control-plane-container> e rilancia."
  exit 1
fi

# Poll: attendi che kube-apiserver sia /healthz=ok, fino a max_seconds.
wait_apiserver() {
  local max=${1:-90} elapsed=0
  while (( elapsed < max )); do
    if kubectl get --raw=/healthz 2>/dev/null | grep -qi 'ok'; then
      echo "✅ kube-apiserver Ready (dopo ${elapsed}s)"
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done
  echo "❌ kube-apiserver non risponde dopo ${max}s"
  return 1
}

# Idempotente: rimuovi qualunque --anonymous-auth=… esistente, poi aggiungi false
docker exec "$CTL" sed -i '\|--anonymous-auth=|d' /etc/kubernetes/manifests/kube-apiserver.yaml
docker exec "$CTL" sed -i '/- kube-apiserver/a\    - --anonymous-auth=false' /etc/kubernetes/manifests/kube-apiserver.yaml

echo "Attendo che kube-apiserver torni Ready dopo il restart del pod statico..."
wait_apiserver 90 || { echo "Controlla: docker exec $CTL crictl logs \$(docker exec $CTL crictl ps -a --name kube-apiserver -q | head -1)"; exit 1; }

APISERVER="https://$(kubectl get endpoints kubernetes -o jsonpath='{.subsets[0].addresses[0].ip}'):6443"
echo
echo "Test anonimo verso $APISERVER (atteso 401):"
curl -k -s -o /dev/null -w "HTTP %{http_code}\n" "$APISERVER/api/v1/namespaces"
echo
echo "✅ Fix applicata."
