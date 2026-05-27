#!/usr/bin/env bash
set -uo pipefail
kubectl delete namespace dev --ignore-not-found
echo "✅ Q03 cleanup completato."
