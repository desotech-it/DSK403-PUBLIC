#!/usr/bin/env bash
# Q14 break: installa Falco (se manca) senza nessuna rule custom per shell.
set -euo pipefail
if ! kubectl get ns falco >/dev/null 2>&1; then
  helm repo add falcosecurity https://falcosecurity.github.io/charts >/dev/null
  helm repo update >/dev/null
  helm upgrade --install falco falcosecurity/falco \
    --namespace falco --create-namespace \
    --set tty=true \
    --set driver.kind=modern_ebpf \
    --set falcosidekick.enabled=false \
    --wait
fi
kubectl -n falco rollout status ds/falco
kubectl -n falco delete configmap falco-custom-rules --ignore-not-found

echo
echo "✅ Stato 'rotto' applicato (Falco installato, niente rule custom)."
