#!/usr/bin/env bash
set -uo pipefail
CTL="${CTL:-dsk102-lab-08-control-plane}"
docker exec "$CTL" sed -i '\|--audit-policy-file=|d' /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null || true
docker exec "$CTL" sed -i '\|--audit-log-|d'        /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null || true
docker exec "$CTL" rm -f /etc/kubernetes/audit-policy.yaml 2>/dev/null || true
docker exec "$CTL" rm -rf /var/log/kubernetes/audit 2>/dev/null || true
kubectl delete secret audit-test --ignore-not-found
echo "✅ Q13 cleanup completato."
