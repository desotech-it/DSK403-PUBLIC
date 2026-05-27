#!/usr/bin/env bash
set -uo pipefail
kubectl delete namespace nonroot --ignore-not-found
echo "✅ Q09 cleanup completato."
