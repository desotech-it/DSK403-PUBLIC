#!/usr/bin/env bash
set -uo pipefail
kubectl delete pod secure-app --ignore-not-found
for N in $(docker ps --format '{{.Names}}' | grep -E 'worker' || true); do
  docker exec "$N" apparmor_parser -R /etc/apparmor.d/k8s-deny-write 2>/dev/null || true
  docker exec "$N" rm -f /etc/apparmor.d/k8s-deny-write 2>/dev/null || true
done
rm -f /tmp/k8s-deny-write
echo "✅ Q05 cleanup completato."
