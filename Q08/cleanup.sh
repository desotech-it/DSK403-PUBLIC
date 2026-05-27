#!/usr/bin/env bash
# Q08 cleanup: rimuove la configurazione (flag + volume + volumeMount) e il Secret demo,
# aspettando che kube-apiserver torni Ready prima di tornare il controllo.
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

if docker ps --format '{{.Names}}' | grep -q "^${CTL}$"; then
  # Verifico se serve davvero patchare (evito restart inutili)
  NEEDS_PATCH=$(docker exec "$CTL" sh -c '
    grep -q -- "--encryption-provider-config=" /etc/kubernetes/manifests/kube-apiserver.yaml && echo yes || echo no
  ' 2>/dev/null || echo no)

  if [[ "$NEEDS_PATCH" == "yes" ]]; then
    docker exec -i "$CTL" python3 <<'PYSCRIPT' 2>/dev/null || true
import yaml
PATH = "/etc/kubernetes/manifests/kube-apiserver.yaml"
try:
    with open(PATH) as f:
        m = yaml.safe_load(f)
except Exception:
    raise SystemExit(0)
c = m["spec"]["containers"][0]
c["command"] = [x for x in c["command"] if not x.startswith("--encryption-provider-config=")]
c["volumeMounts"] = [v for v in c.get("volumeMounts", []) if v.get("name") != "encryption-config"]
m["spec"]["volumes"] = [v for v in m["spec"].get("volumes", []) if v.get("name") != "encryption-config"]
with open(PATH, "w") as f:
    yaml.safe_dump(m, f, default_flow_style=False)
PYSCRIPT
    echo "Manifest ripristinato. Attendo che kube-apiserver torni Ready..."
    wait_apiserver 120 || true
  fi

  docker exec "$CTL" rm -f /etc/kubernetes/encryption-config.yaml 2>/dev/null || true
fi

kubectl delete secret demo --ignore-not-found 2>/dev/null || true
echo "✅ Q08 cleanup completato."
