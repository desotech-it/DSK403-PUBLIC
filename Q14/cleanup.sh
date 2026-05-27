#!/usr/bin/env bash
set -uo pipefail
kubectl delete pod target --ignore-not-found
kubectl -n falco delete configmap falco-custom-rules --ignore-not-found
echo "✅ Q14 cleanup completato. (Falco lasciato installato.)"
