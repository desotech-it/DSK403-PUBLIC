#!/usr/bin/env bash
# Q13 cleanup — rimuove audit policy + flag dal manifest, log dir,
# secret di test, e aspetta che kube-apiserver torni Ready.
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
  HAD_AUDIT=$(docker exec "$CTL" sh -c '
    grep -q -- "--audit-policy-file=" /etc/kubernetes/manifests/kube-apiserver.yaml && echo yes || echo no
  ' 2>/dev/null || echo no)

  docker exec "$CTL" sed -i '\|--audit-policy-file=|d' /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null || true
  docker exec "$CTL" sed -i '\|--audit-log-|d'        /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null || true
  docker exec "$CTL" rm -f /etc/kubernetes/audit-policy.yaml 2>/dev/null || true
  docker exec "$CTL" rm -rf /var/log/kubernetes/audit 2>/dev/null || true

  if [[ "$HAD_AUDIT" == "yes" ]]; then
    wait_apiserver 120 || true
  fi
fi

# Secret di test eventualmente creati nei verify (es. audit-test, audit-test-*)
kubectl delete secret audit-test --ignore-not-found 2>/dev/null || true
for s in $(kubectl get secrets -n default --no-headers -o custom-columns=NAME:.metadata.name 2>/dev/null | grep '^audit-test' || true); do
  kubectl delete secret "$s" --ignore-not-found 2>/dev/null || true
done

echo "✅ Q13 cleanup completato."
