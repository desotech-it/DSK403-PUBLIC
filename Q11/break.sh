#!/usr/bin/env bash
# Q11 break: installa Kyverno (se manca) e genera una keypair cosign per il lab.
# Non crea ancora nessuna ClusterPolicy verifyImages: lo stato è "qualsiasi immagine accettata".
set -euo pipefail

if ! kubectl get ns kyverno >/dev/null 2>&1; then
  helm repo add kyverno https://kyverno.github.io/kyverno/ >/dev/null
  helm repo update >/dev/null
  helm upgrade --install kyverno kyverno/kyverno -n kyverno --create-namespace --wait
fi
kubectl -n kyverno get pods

# Genera una keypair cosign demo se assente e cosign è disponibile
if command -v cosign >/dev/null; then
  if [[ ! -f /tmp/cosign.key || ! -f /tmp/cosign.pub ]]; then
    COSIGN_PASSWORD="" cosign generate-key-pair --output-key-prefix /tmp/cosign
  fi
  echo
  echo "Public key (da usare nella ClusterPolicy):"
  cat /tmp/cosign.pub
else
  echo
  echo "⚠️  cosign non installato. Per generare manualmente la keypair:"
  echo "    brew install cosign  # macOS"
  echo "    # Linux: vedi https://docs.sigstore.dev/cosign/installation/"
fi

echo
echo "✅ Stato 'rotto' applicato (admission accetta qualunque immagine):"
echo "   kubectl run unsigned --image=registry.example.com/myapp:unsigned --dry-run=server  # accettato"
