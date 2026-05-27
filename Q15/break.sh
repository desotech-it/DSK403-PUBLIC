#!/usr/bin/env bash
# Q15 break: crea ns tenants-untrusted; assicura Kyverno installato; NIENTE RuntimeClass/policy ancora.
set -euo pipefail

F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
apiVersion: v1
kind: Namespace
metadata:
  name: tenants-untrusted
YAML
kubectl apply -f "$F"
rm -f "$F"

if ! kubectl get ns kyverno >/dev/null 2>&1; then
  helm repo add kyverno https://kyverno.github.io/kyverno/ >/dev/null
  helm repo update >/dev/null
  helm upgrade --install kyverno kyverno/kyverno -n kyverno --create-namespace --wait
fi

# Pulisce eventuali risorse di run precedenti
kubectl delete runtimeclass gvisor --ignore-not-found
kubectl delete clusterpolicy set-gvisor-on-untrusted --ignore-not-found

echo
echo "✅ Stato 'rotto' applicato (ns tenants-untrusted creato, niente sandbox):"
echo "   kubectl run probe -n tenants-untrusted --image=alpine:3.20 -- sleep 60"
echo "   kubectl -n tenants-untrusted get pod probe -o jsonpath='{.spec.runtimeClassName}'"
echo "   (atteso: vuoto = runtime di default)"
