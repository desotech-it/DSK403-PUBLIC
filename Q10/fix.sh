#!/usr/bin/env bash
# Q10 fix: configura AdmissionConfiguration con ImagePolicyWebhook nel kube-apiserver
set -euo pipefail
CTL="${CTL:-dsk102-lab-08-control-plane}"

if ! docker ps --format '{{.Names}}' | grep -q "^${CTL}$"; then
  echo "⚠️  Container '${CTL}' non trovato. Imposta CTL=... e rilancia."
  exit 1
fi

# AdmissionConfiguration + kubeconfig dummy (per esempio didattico)
ADM=$(mktemp)
cat <<'EOFA' >"$ADM"
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/admission/image-policy-kubeconfig.yaml
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: false
EOFA

KCFG=$(mktemp)
cat <<'EOFK' >"$KCFG"
apiVersion: v1
kind: Config
clusters:
- name: image-scanner
  cluster:
    server: https://image-scanner.default.svc:443/v1/scan
users:
- name: apiserver
  user: {}
current-context: webhook
contexts:
- name: webhook
  context: { cluster: image-scanner, user: apiserver }
EOFK

docker exec "$CTL" mkdir -p /etc/kubernetes/admission
docker cp "$ADM"  "$CTL":/etc/kubernetes/admission/admission-config.yaml
docker cp "$KCFG" "$CTL":/etc/kubernetes/admission/image-policy-kubeconfig.yaml
rm -f "$ADM" "$KCFG"

# Aggiungi la flag a kube-apiserver (idempotente)
docker exec "$CTL" sed -i '\|--admission-control-config-file=|d' /etc/kubernetes/manifests/kube-apiserver.yaml
docker exec "$CTL" sed -i '/- kube-apiserver/a\    - --admission-control-config-file=/etc/kubernetes/admission/admission-config.yaml' /etc/kubernetes/manifests/kube-apiserver.yaml

# Abilita ImagePolicyWebhook nei plugin attivi (se la flag --enable-admission-plugins esiste già)
docker exec "$CTL" sed -i '/--enable-admission-plugins=/ s|=\(.*\)|=\1,ImagePolicyWebhook|' /etc/kubernetes/manifests/kube-apiserver.yaml || true

echo "Attendo il restart del pod kube-apiserver (~40s)..."
sleep 40

echo
echo "✅ Fix applicata. Verifica:"
echo "   kubectl run bad --image=registry.example.com/bad-image:1.0 --dry-run=server"
echo "   (atteso: errore di admission)"
