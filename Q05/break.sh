#!/usr/bin/env bash
# Q05 break: applica un Pod che referenzia un profilo AppArmor NON ancora caricato sui nodi.
# Il profilo k8s-deny-write esiste solo come file qui sotto, non è nel kernel di nessun nodo.
set -euo pipefail
PROFILE=/tmp/k8s-deny-write
cat <<'AAPF' >"$PROFILE"
#include <tunables/global>
profile k8s-deny-write flags=(attach_disconnected) {
  #include <abstractions/base>
  file,
  deny /** w,
  / r,
  /** r,
  /usr/** mrix,
  /bin/** mrix,
}
AAPF

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
kubectl delete pod secure-app --ignore-not-found
kubectl apply -f "$F"
rm -f "$F"

echo
echo "✅ Stato 'rotto' applicato (profilo NON caricato sui nodi)."
echo "   Il file del profilo è stato salvato in: $PROFILE"
echo "   Il pod ora è in Blocked. Verifica:"
echo "     kubectl describe pod secure-app | grep -i apparmor"
