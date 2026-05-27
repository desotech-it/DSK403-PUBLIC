#!/usr/bin/env bash
# Q08 fix: configura EncryptionConfiguration con aescbc + identity, riavvia apiserver, riscrive i Secret.
#
# Modifica al manifest statico fatta in Python via docker exec per evitare sed
# fragili: aggiunge sia la flag --encryption-provider-config sia il volumeMount
# e il volume hostPath corrispondenti.
set -euo pipefail
CTL="${CTL:-dsk102-lab-08-control-plane}"

if ! docker ps --format '{{.Names}}' | grep -q "^${CTL}$"; then
  echo "⚠️  Container '${CTL}' non trovato. Imposta CTL=... e rilancia."
  exit 1
fi

# Pre-check: serve python3 + pyyaml nel container del control plane
if ! docker exec "$CTL" sh -c 'command -v python3 && python3 -c "import yaml" 2>/dev/null'; then
  echo "Installo python3-yaml nel container $CTL (una tantum)..."
  docker exec "$CTL" sh -c 'apt-get update -qq && apt-get install -y -qq python3-yaml >/dev/null 2>&1'
fi

# Helper: poll /healthz fino a max_seconds
wait_apiserver() {
  local max=${1:-120} elapsed=0
  while (( elapsed < max )); do
    if kubectl get --raw=/healthz 2>/dev/null | grep -qi 'ok'; then
      echo "✅ kube-apiserver Ready (dopo ${elapsed}s)"
      return 0
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done
  echo "❌ kube-apiserver non risponde dopo ${max}s"
  return 1
}

# 1) Genera EncryptionConfiguration e copialo nel control plane
KEY=$(head -c 32 /dev/urandom | base64 -w0)
ENC_CONF=$(mktemp)
cat >"$ENC_CONF" <<EOFINNER
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

# 2) Patcha il manifest statico (flag + volume + volumeMount) in modo idempotente
docker exec -i "$CTL" python3 <<'PYSCRIPT'
import yaml
PATH = "/etc/kubernetes/manifests/kube-apiserver.yaml"
with open(PATH) as f:
    m = yaml.safe_load(f)

c = m["spec"]["containers"][0]

# Flag
c["command"] = [x for x in c["command"] if not x.startswith("--encryption-provider-config=")]
c["command"].append("--encryption-provider-config=/etc/kubernetes/encryption-config.yaml")

# volumeMount
c.setdefault("volumeMounts", [])
c["volumeMounts"] = [v for v in c["volumeMounts"] if v.get("name") != "encryption-config"]
c["volumeMounts"].append({
    "name": "encryption-config",
    "mountPath": "/etc/kubernetes/encryption-config.yaml",
    "readOnly": True,
})

# volume
m["spec"].setdefault("volumes", [])
m["spec"]["volumes"] = [v for v in m["spec"]["volumes"] if v.get("name") != "encryption-config"]
m["spec"]["volumes"].append({
    "name": "encryption-config",
    "hostPath": {
        "path": "/etc/kubernetes/encryption-config.yaml",
        "type": "File",
    },
})

with open(PATH, "w") as f:
    yaml.safe_dump(m, f, default_flow_style=False)
print("✅ Manifest patched")
PYSCRIPT

# 3) Attendi che kube-apiserver torni Ready dopo il restart
echo "Attendo che kube-apiserver torni Ready (può richiedere 60-120s)..."
wait_apiserver 120 || {
  echo "Controlla i log: docker exec $CTL sh -c 'crictl logs \$(crictl ps -a --name kube-apiserver -q | head -1) 2>&1 | tail -30'"
  exit 1
}

# 4) Riscrivi tutti i Secret per forzare la cifratura via aescbc
echo "Rewriting tutti i Secret per forzarne la cifratura..."
kubectl get secrets -A -o json | kubectl replace -f - >/dev/null
echo

echo "✅ Fix applicata. Verifica in etcd (atteso: prefisso 'k8s:enc:aescbc:v1:...'):"
echo "   docker exec $CTL sh -c 'ETCDCTL_API=3 etcdctl \\"
echo "     --endpoints=https://127.0.0.1:2379 \\"
echo "     --cacert=/etc/kubernetes/pki/etcd/ca.crt \\"
echo "     --cert=/etc/kubernetes/pki/etcd/server.crt \\"
echo "     --key=/etc/kubernetes/pki/etcd/server.key \\"
echo "     get /registry/secrets/default/demo' | hexdump -C | head -3"
