#!/usr/bin/env bash
# Q12 break: installa Trivy (se manca) e prepara una directory di manifest "bad" da scansionare.
set -euo pipefail

if ! command -v trivy >/dev/null; then
  if command -v brew >/dev/null; then
    brew install aquasecurity/trivy/trivy
  else
    curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \
      | sudo sh -s -- -b /usr/local/bin
  fi
fi
trivy --version

mkdir -p /tmp/q12-manifests
cat <<'YAML' >/tmp/q12-manifests/bad-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: bad-pod
spec:
  hostNetwork: true
  hostPID: true
  containers:
  - name: c
    image: nginx:1.18.0
    securityContext:
      privileged: true
      runAsUser: 0
YAML

echo
echo "✅ Pronto. Manifest di test in /tmp/q12-manifests/. Non c'è ancora nessun report."
