#!/usr/bin/env bash
set -uo pipefail
kubectl delete clusterpolicy verify-cosign-signatures --ignore-not-found
echo "✅ Q11 cleanup completato. (Kyverno e cosign.* lasciati installati per altri lab)."
