#!/usr/bin/env bash
# Q11 fix: applica una ClusterPolicy Kyverno verifyImages.
# Per il lab usa la PEM in /tmp/cosign.pub (generata da break.sh) oppure una placeholder.
set -euo pipefail
PUB=""
if [[ -f /tmp/cosign.pub ]]; then
  PUB=$(cat /tmp/cosign.pub)
else
  PUB="-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE_PLACEHOLDER_FAKE_KEY_VALUE
-----END PUBLIC KEY-----"
fi

# La PEM va indentata di 14 spazi per stare correttamente sotto 'publicKeys: |-'
# (altrimenti '-----BEGIN PUBLIC KEY-----' viene interpretato da YAML come
#  separatore di documento '---' e l'apply fallisce).
PUB_INDENTED=$(printf '%s\n' "$PUB" | sed 's/^/              /')

F=$(mktemp --suffix=.yaml)
cat <<YAML >"$F"
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-cosign-signatures
spec:
  validationFailureAction: Enforce
  webhookTimeoutSeconds: 30
  failurePolicy: Fail
  rules:
  - name: verify-signatures-registry-example
    match:
      any:
      - resources:
          kinds: [Pod]
    verifyImages:
    - imageReferences:
      - "registry.example.com/*"
      attestors:
      - entries:
        - keys:
            publicKeys: |-
${PUB_INDENTED}
YAML
kubectl apply -f "$F"
rm -f "$F"

echo
echo "✅ Fix applicata. Verifica:"
echo "   kubectl run unsigned --image=registry.example.com/myapp:unsigned --dry-run=server  # rifiutato"
echo "   kubectl run external --image=nginx:1.27 --dry-run=server                            # accettato"
