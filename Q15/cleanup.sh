#!/usr/bin/env bash
# Q15 cleanup — rimuove ClusterPolicy, RuntimeClass, namespace tenants-untrusted
# e pod di test eventualmente creati durante i verify ('probe' nel ns target,
# 'other' nel default per il test negativo).
set -uo pipefail
kubectl delete clusterpolicy set-gvisor-on-untrusted --ignore-not-found 2>/dev/null || true
kubectl delete runtimeclass gvisor --ignore-not-found 2>/dev/null || true
kubectl delete pod other --ignore-not-found 2>/dev/null || true
kubectl delete namespace tenants-untrusted --ignore-not-found 2>/dev/null || true
echo "✅ Q15 cleanup completato."
