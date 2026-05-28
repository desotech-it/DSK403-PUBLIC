#!/usr/bin/env bash
# Q02 cleanup: rimuove la flag --anonymous-auth=false (torna al default true)
# e attende che kube-apiserver torni Ready prima di restituire il prompt.
set -uo pipefail
CTL="${CTL:-dsk102-lab-08-control-plane}"

wait_apiserver() {
  local max=${1:-120} elapsed=0
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

if docker ps --format '{{.Names}}' | grep -q "^${CTL}$"; then
  if docker exec "$CTL" grep -q -- '--anonymous-auth=false' /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null; then
    docker exec "$CTL" sed -i '\|--anonymous-auth=|d' /etc/kubernetes/manifests/kube-apiserver.yaml
    wait_apiserver 120 || true
  fi
fi
echo "✅ Q02 cleanup completato."
