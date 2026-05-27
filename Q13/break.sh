#!/usr/bin/env bash
# Q13 break: verifica che kube-apiserver NON abbia audit logging configurato.
set -uo pipefail
CTL="${CTL:-dsk102-lab-08-control-plane}"

# Rimuovi configurazione audit residua, se presente
docker exec "$CTL" sed -i '\|--audit-policy-file=|d' /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null || true
docker exec "$CTL" sed -i '\|--audit-log-|d'        /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null || true

echo
echo "✅ Stato 'rotto' applicato (audit NON configurato):"
echo "   docker exec $CTL grep audit /etc/kubernetes/manifests/kube-apiserver.yaml || echo '(nessuna flag audit)'"
