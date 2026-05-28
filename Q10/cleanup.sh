#!/usr/bin/env bash
# Q10 cleanup — rimuove ImagePolicyWebhook (flag + config), service del finto
# scanner, e pod di test eventualmente creati con `kubectl run bad/good`.
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

# Manifest patches (idempotenti)
if docker ps --format '{{.Names}}' | grep -q "^${CTL}$"; then
  HAD_CFG=$(docker exec "$CTL" sh -c '
    grep -q -- "--admission-control-config-file=" /etc/kubernetes/manifests/kube-apiserver.yaml && echo yes || echo no
  ' 2>/dev/null || echo no)

  docker exec "$CTL" sed -i '\|--admission-control-config-file=|d' /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null || true
  docker exec "$CTL" sed -i '/--enable-admission-plugins=/ s|,ImagePolicyWebhook||g' /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null || true
  docker exec "$CTL" rm -rf /etc/kubernetes/admission 2>/dev/null || true

  if [[ "$HAD_CFG" == "yes" ]]; then
    wait_apiserver 120 || true
  fi
fi

# Test pods (creati manualmente nei verify)
kubectl delete pod bad good --ignore-not-found 2>/dev/null || true
# Webhook finto
kubectl delete deploy image-scanner -n default --ignore-not-found
kubectl delete svc image-scanner -n default --ignore-not-found

echo "✅ Q10 cleanup completato."
