#!/usr/bin/env bash
set -uo pipefail
kubectl delete namespace prod --ignore-not-found
echo "✅ Q07 cleanup completato."
