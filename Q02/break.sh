#!/usr/bin/env bash
# Q02 break: verifica lo stato attuale di --anonymous-auth.
# Su un cluster kubeadm "fresh" il flag è già a true (default), quindi lo stato è "rotto" di default.
# Lo script si limita a rimuovere un eventuale --anonymous-auth=false residuo (per riproducibilità).
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

# Verifica se serve riscrivere il manifest (evita restart inutili del pod statico).
if docker exec "$CTL" grep -q -- '--anonymous-auth=false' /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null; then
  echo "Rimuovo --anonymous-auth=false dal manifest (atteso restart pod ~30-60s)..."
  docker exec "$CTL" sed -i '\|--anonymous-auth=false|d' /etc/kubernetes/manifests/kube-apiserver.yaml
  wait_apiserver 90 || exit 1
else
  echo "Manifest già allo stato 'rotto' (--anonymous-auth non specificato = default true)."
fi

APISERVER="https://$(kubectl get endpoints kubernetes -o jsonpath='{.subsets[0].addresses[0].ip}'):6443"
echo
echo "Test anonimo verso $APISERVER (atteso 403 = autenticato come anonymous):"
curl -k -s -o /dev/null -w "HTTP %{http_code}\n" "$APISERVER/api/v1/namespaces"
