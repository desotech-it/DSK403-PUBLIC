#!/usr/bin/env bash
# Q11 cleanup — rimuove la ClusterPolicy e i pod di test eventualmente creati
# durante i verify (signed/unsigned/external). Lascia Kyverno e la keypair
# cosign in /tmp installati per non rompere altri lab e per riutilizzo.
set -uo pipefail
kubectl delete clusterpolicy verify-cosign-signatures --ignore-not-found 2>/dev/null || true
kubectl delete pod signed unsigned external --ignore-not-found 2>/dev/null || true
echo "✅ Q11 cleanup completato. (Kyverno e /tmp/cosign.* lasciati intatti.)"
