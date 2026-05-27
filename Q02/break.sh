#!/usr/bin/env bash
# Q02 break: verifica lo stato attuale di --anonymous-auth.
# Su un cluster kubeadm "fresh" il flag è già a true (default), quindi lo stato è "rotto" di default.
# Lo script si limita a forzare il flag a true se per caso è già a false (per riproducibilità).
set -uo pipefail
CTL="${CTL:-dsk102-lab-08-control-plane}"

if ! docker ps --format '{{.Names}}' | grep -q "^${CTL}$"; then
  echo "⚠️  Container '${CTL}' non trovato. Imposta CTL=<nome-control-plane-container> e rilancia."
  exit 1
fi

# Rimuovi eventuale --anonymous-auth=false esistente (lasciando il default true)
docker exec "$CTL" sed -i '\|--anonymous-auth=false|d' /etc/kubernetes/manifests/kube-apiserver.yaml
sleep 15
APISERVER="https://$(kubectl get endpoints kubernetes -o jsonpath='{.subsets[0].addresses[0].ip}'):6443"
echo "Test anonimo verso $APISERVER (atteso 403 = autenticato come anonymous):"
curl -k -s -o /dev/null -w "HTTP %{http_code}\n" "$APISERVER/api/v1/namespaces"
