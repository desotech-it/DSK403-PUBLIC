#!/usr/bin/env bash
# Q05 fix: copia il profilo su tutti i worker node e lo carica con apparmor_parser.
#
# Requisiti del cluster:
#   - AppArmor abilitato nel kernel del nodo (LSM esposto).
#   - apparmor_parser + apparmor-utils installati nel nodo.
#
# Su kind (kindest/node) NON FUNZIONA out-of-the-box: il "nodo" è un container
# Docker il cui kernel non espone AppArmor. In quel caso lo script si ferma
# e ti dice di provarlo su un cluster kubeadm su VM, oppure ricreare il kind
# con flag/immagine custom che esponga AppArmor.

set -euo pipefail
PROFILE=/tmp/k8s-deny-write
if [[ ! -f "$PROFILE" ]]; then
  echo "⚠️  $PROFILE non esiste. Esegui prima break.sh."
  exit 1
fi

# Trova i nodi worker del cluster kind
NODES=$(docker ps --format '{{.Names}}' | grep -E 'worker' || true)
if [[ -z "$NODES" ]]; then
  echo "⚠️  Nessun nodo worker kind trovato. Imposta NODES=... e rilancia manualmente."
  exit 1
fi

# Pre-check: AppArmor è davvero disponibile nei nodi?
FIRST_NODE=$(echo "$NODES" | head -1)
if ! docker exec "$FIRST_NODE" sh -c 'test -e /sys/kernel/security/apparmor || test -e /proc/sys/kernel/apparmor_enabled' 2>/dev/null; then
  cat <<'ERR'
❌ AppArmor NON è abilitato nel kernel del nodo $FIRST_NODE.

Questo è un limite del setup kind (containers-as-nodes): il kernel del
container non espone LSM AppArmor, quindi apparmor_parser non può
caricare nessun profilo, e anche se ci riuscisse il kubelet non saprebbe
applicarlo al container del pod.

Q05 non è eseguibile su questo cluster. Soluzioni:
  - Eseguilo su un cluster kubeadm su una VM Ubuntu/Debian standard
    (è il setup tipico dell'esame CKS).
  - Oppure ricrea il kind con un'immagine custom che includa apparmor-utils
    e configura il containerd dell'host per esporre /sys/kernel/security.
ERR
  echo
  echo "Saltato. Esegui 'bash cleanup.sh' per togliere il pod Blocked, poi passa al Q06."
  exit 2
fi

for N in $NODES; do
  echo "--- carico profilo su $N ---"
  docker exec "$N" mkdir -p /etc/apparmor.d
  docker cp "$PROFILE" "$N":/etc/apparmor.d/k8s-deny-write
  docker exec "$N" apparmor_parser -q -r /etc/apparmor.d/k8s-deny-write
  docker exec "$N" aa-status 2>/dev/null | grep -E 'k8s-deny-write' || true
done

# Ricicla il pod (il fallimento iniziale è sticky)
kubectl delete pod secure-app --ignore-not-found
F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
spec:
  securityContext:
    appArmorProfile:
      type: Localhost
      localhostProfile: k8s-deny-write
  containers:
  - name: app
    image: alpine:3.20
    command: ["sh", "-c", "sleep 36000"]
YAML
kubectl apply -f "$F"
rm -f "$F"
kubectl wait --for=condition=Ready pod/secure-app --timeout=60s

echo
echo "✅ Fix applicata. Verifica:"
echo "   kubectl exec secure-app -- sh -c 'touch /tmp/x'  # deve fallire (Permission denied)"
