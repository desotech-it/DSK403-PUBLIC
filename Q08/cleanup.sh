#!/usr/bin/env bash
# Q08 cleanup — teardown sicuro della encryption at rest.
#
# fix.sh aveva fatto un kubectl get secrets -A | kubectl replace, quindi TUTTI
# i Secret del cluster sono ora cifrati con aescbc, non solo 'demo'. Se ci
# limitassimo a togliere la encryption-config tutti quei Secret diventerebbero
# orfani-cifrati (errore "identity transformer tried to read encrypted data"
# su ogni LIST). Quindi facciamo un teardown in due fasi:
#   1) Inverti l'ordine dei provider (identity PRIMA, aescbc DOPO) -> le
#      scritture vanno in chiaro, le letture sanno ancora decifrare.
#      Restart apiserver. Rewrite di tutti i Secret -> ora in chiaro.
#   2) Rimuovi la encryption-config dal manifest + dal disco. Restart
#      apiserver. Tutto è in chiaro, nessun orfano cifrato.
set -uo pipefail
CTL="${CTL:-dsk102-lab-08-control-plane}"

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

if ! docker ps --format '{{.Names}}' | grep -q "^${CTL}$"; then
  kubectl delete secret demo --ignore-not-found 2>/dev/null || true
  echo "✅ Q08 cleanup (skipped CTL ops: container '$CTL' non trovato)."
  exit 0
fi

has_enc_flag() {
  docker exec "$CTL" grep -q -- "--encryption-provider-config=" \
    /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null
}

has_enc_file() {
  docker exec "$CTL" test -f /etc/kubernetes/encryption-config.yaml 2>/dev/null
}

# Niente da fare se non c'è proprio nessuna traccia di encryption-config
if ! has_enc_flag && ! has_enc_file; then
  kubectl delete secret demo --ignore-not-found 2>/dev/null || true
  echo "✅ Q08 cleanup completato (nessuna encryption-config trovata)."
  exit 0
fi

# === FASE 1: identity-first, restart, rewrite Secrets in chiaro ===
if has_enc_flag && has_enc_file; then
  echo "→ Fase 1: ricolloco 'identity' come primo provider e attendo il restart..."
  docker exec -i "$CTL" python3 <<'PYSCRIPT' 2>/dev/null || true
import yaml
P = "/etc/kubernetes/encryption-config.yaml"
with open(P) as f:
    cfg = yaml.safe_load(f)
providers = cfg["resources"][0]["providers"]
new = [{"identity": {}}]
for p in providers:
    if "identity" not in p:
        new.append(p)
cfg["resources"][0]["providers"] = new
with open(P, "w") as f:
    yaml.safe_dump(cfg, f, default_flow_style=False)
print("✅ encryption-config: identity is now first")
PYSCRIPT

  # Force apiserver restart: move manifest OUT then back IN.
  # 'touch' alone is not enough because kubelet hashes the manifest content,
  # not its mtime, so it would not detect a no-op change.
  echo "→ Forzo restart kube-apiserver (move out + sleep + move in)..."
  docker exec "$CTL" mv /etc/kubernetes/manifests/kube-apiserver.yaml /tmp/kube-apiserver.yaml.tmp
  # Aspetta che il vecchio pod sparisca davvero
  for i in $(seq 1 30); do
    if ! kubectl get --raw=/healthz 2>/dev/null | grep -qi 'ok'; then
      break
    fi
    sleep 1
  done
  docker exec "$CTL" mv /tmp/kube-apiserver.yaml.tmp /etc/kubernetes/manifests/kube-apiserver.yaml
  wait_apiserver 120 || { echo "Fase 1: apiserver non torna su. Interrompo."; exit 1; }

  echo "→ Riscrivo tutti i Secret per portarli in chiaro (passano da identity)..."
  kubectl get secrets -A -o json | kubectl replace -f - >/dev/null || true
fi

# === FASE 2: rimuovi flag + volumeMount + volume dal manifest, restart ===
echo "→ Fase 2: rimuovo encryption-config da manifest e disco, attendo restart..."
docker exec -i "$CTL" python3 <<'PYSCRIPT' 2>/dev/null || true
import yaml
P = "/etc/kubernetes/manifests/kube-apiserver.yaml"
try:
    with open(P) as f:
        m = yaml.safe_load(f)
except Exception:
    raise SystemExit(0)
c = m["spec"]["containers"][0]
c["command"] = [x for x in c["command"] if not x.startswith("--encryption-provider-config=")]
c["volumeMounts"] = [v for v in c.get("volumeMounts", []) if v.get("name") != "encryption-config"]
m["spec"]["volumes"] = [v for v in m["spec"].get("volumes", []) if v.get("name") != "encryption-config"]
with open(P, "w") as f:
    yaml.safe_dump(m, f, default_flow_style=False)
PYSCRIPT

wait_apiserver 120 || true

docker exec "$CTL" rm -f /etc/kubernetes/encryption-config.yaml 2>/dev/null || true

# === FASE 3: pulizia residui ===
kubectl delete secret demo --ignore-not-found 2>/dev/null || true

echo "✅ Q08 cleanup completato (Secrets in chiaro, encryption-config rimossa)."
