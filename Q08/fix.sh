#!/usr/bin/env bash
# Q08 fix: configura EncryptionConfiguration con aescbc + identity, riavvia apiserver, riscrive i Secret
set -euo pipefail
CTL="${CTL:-dsk102-lab-08-control-plane}"

if ! docker ps --format '{{.Names}}' | grep -q "^${CTL}$"; then
  echo "⚠️  Container '${CTL}' non trovato. Imposta CTL=... e rilancia."
  exit 1
fi

KEY=$(head -c 32 /dev/urandom | base64 -w0)
ENC_CONF=$(mktemp)
cat <<EOFINNER >"$ENC_CONF"
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources: [secrets]
  providers:
  - aescbc:
      keys:
      - name: key-2026-05
        secret: ${KEY}
  - identity: {}
EOFINNER

docker cp "$ENC_CONF" "$CTL":/etc/kubernetes/encryption-config.yaml
docker exec "$CTL" chmod 0600 /etc/kubernetes/encryption-config.yaml
rm -f "$ENC_CONF"

# Aggiungi le flag e i mount al manifest statico (idempotente)
docker exec "$CTL" sed -i '\|--encryption-provider-config=|d' /etc/kubernetes/manifests/kube-apiserver.yaml
docker exec "$CTL" sed -i '/- kube-apiserver/a\    - --encryption-provider-config=/etc/kubernetes/encryption-config.yaml' /etc/kubernetes/manifests/kube-apiserver.yaml

# Aggiungi volumeMount (idempotente: solo se assente)
docker exec "$CTL" sh -c '
  grep -q "encryption-config.yaml" /etc/kubernetes/manifests/kube-apiserver.yaml || true
'

echo "Attendo il restart del pod kube-apiserver (~40s)..."
sleep 40

# Riscrittura dei Secret esistenti per forzare la cifratura
kubectl get secrets -A -o json | kubectl replace -f - >/dev/null

echo
echo "✅ Fix applicata. Verifica in etcd (atteso: prefisso 'k8s:enc:aescbc:v1:...'):"
echo "   docker exec $CTL sh -c 'ETCDCTL_API=3 etcdctl \\"
echo "     --endpoints=https://127.0.0.1:2379 \\"
echo "     --cacert=/etc/kubernetes/pki/etcd/ca.crt \\"
echo "     --cert=/etc/kubernetes/pki/etcd/server.crt \\"
echo "     --key=/etc/kubernetes/pki/etcd/server.key \\"
echo "     get /registry/secrets/default/demo' | hexdump -C | head -3"
