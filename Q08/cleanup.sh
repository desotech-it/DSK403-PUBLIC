#!/usr/bin/env bash
# Q08 cleanup: rimuove la configurazione + il Secret demo
set -uo pipefail
CTL="${CTL:-dsk102-lab-08-control-plane}"
docker exec "$CTL" sed -i '\|--encryption-provider-config=|d' /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null || true
docker exec "$CTL" rm -f /etc/kubernetes/encryption-config.yaml 2>/dev/null || true
kubectl delete secret demo --ignore-not-found
echo "✅ Q08 cleanup completato (le flag potrebbero richiedere un restart del pod apiserver per riflettersi)."
