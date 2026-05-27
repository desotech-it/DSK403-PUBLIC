#!/usr/bin/env bash
# Q08 cleanup: rimuove la configurazione (flag + volume + volumeMount) e il Secret demo.
set -uo pipefail
CTL="${CTL:-dsk102-lab-08-control-plane}"

if docker ps --format '{{.Names}}' | grep -q "^${CTL}$"; then
  # Patch del manifest in Python (rimuove flag/volume/volumeMount in modo idempotente)
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

  docker exec "$CTL" rm -f /etc/kubernetes/encryption-config.yaml 2>/dev/null || true
fi

kubectl delete secret demo --ignore-not-found
echo "✅ Q08 cleanup completato. (Il pod kube-apiserver si riavvia in ~60s.)"
