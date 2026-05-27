#!/usr/bin/env bash
set -uo pipefail
kubectl delete pod risky --ignore-not-found
echo "✅ Q06 cleanup completato."
