#!/usr/bin/env bash
set -uo pipefail
kubectl delete clusterpolicy set-gvisor-on-untrusted --ignore-not-found
kubectl delete runtimeclass gvisor --ignore-not-found
kubectl delete namespace tenants-untrusted --ignore-not-found
echo "✅ Q15 cleanup completato."
