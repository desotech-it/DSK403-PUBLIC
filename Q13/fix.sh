#!/usr/bin/env bash
# Q13 fix: crea audit-policy.yaml + aggiunge le flag a kube-apiserver
set -euo pipefail
CTL="${CTL:-dsk102-lab-08-control-plane}"

if ! docker ps --format '{{.Names}}' | grep -q "^${CTL}$"; then
  echo "⚠️  Container '${CTL}' non trovato. Imposta CTL=... e rilancia."
  exit 1
fi

POL=$(mktemp)
cat <<'YAML' >"$POL"
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages: [RequestReceived]
rules:
- level: None
  users:
  - "system:serviceaccount:kube-system:token-cleaner"
  - "system:serviceaccount:kube-system:service-account-controller"
  - "system:serviceaccount:kube-system:generic-garbage-collector"
  resources:
  - group: ""
    resources: [secrets]
- level: RequestResponse
  verbs: [create, update, patch, delete]
  resources:
  - group: ""
    resources: [secrets]
- level: Metadata
YAML
docker cp "$POL" "$CTL":/etc/kubernetes/audit-policy.yaml
docker exec "$CTL" chmod 0600 /etc/kubernetes/audit-policy.yaml
docker exec "$CTL" mkdir -p /var/log/kubernetes/audit
docker exec "$CTL" chmod 0750 /var/log/kubernetes/audit
rm -f "$POL"

# Aggiungi le flag (idempotente)
docker exec "$CTL" sed -i '\|--audit-policy-file=|d' /etc/kubernetes/manifests/kube-apiserver.yaml
docker exec "$CTL" sed -i '\|--audit-log-|d'        /etc/kubernetes/manifests/kube-apiserver.yaml
docker exec "$CTL" sed -i '/- kube-apiserver/a\    - --audit-log-maxsize=100'    /etc/kubernetes/manifests/kube-apiserver.yaml
docker exec "$CTL" sed -i '/- kube-apiserver/a\    - --audit-log-maxbackup=10'   /etc/kubernetes/manifests/kube-apiserver.yaml
docker exec "$CTL" sed -i '/- kube-apiserver/a\    - --audit-log-maxage=30'      /etc/kubernetes/manifests/kube-apiserver.yaml
docker exec "$CTL" sed -i '/- kube-apiserver/a\    - --audit-log-path=/var/log/kubernetes/audit/audit.log' /etc/kubernetes/manifests/kube-apiserver.yaml
docker exec "$CTL" sed -i '/- kube-apiserver/a\    - --audit-policy-file=/etc/kubernetes/audit-policy.yaml' /etc/kubernetes/manifests/kube-apiserver.yaml

echo "Attendo restart del pod (~40s)..."
sleep 40

echo
echo "✅ Fix applicata. Test:"
echo "   kubectl create secret generic audit-test --from-literal=k=v"
echo "   docker exec $CTL grep '\"resource\":\"secrets\"' /var/log/kubernetes/audit/audit.log | tail -1"
