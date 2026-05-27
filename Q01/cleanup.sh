#!/usr/bin/env bash
# Q01 cleanup
set -euo pipefail
kubectl delete namespace prod --ignore-not-found
echo "✅ Q01 cleanup completato."
