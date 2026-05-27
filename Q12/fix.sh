#!/usr/bin/env bash
# Q12 fix: esegue i tre scan e salva i report nella home dello studente.
set -uo pipefail

trivy image --severity HIGH,CRITICAL --ignore-unfixed nginx:1.18.0 \
  > ~/report-image.txt 2>&1
echo "✅ ~/report-image.txt"

trivy config --severity HIGH,CRITICAL /tmp/q12-manifests/ \
  > ~/report-config.txt 2>&1
echo "✅ ~/report-config.txt"

trivy k8s --report=summary --severity HIGH,CRITICAL cluster \
  > ~/report-cluster.txt 2>&1
echo "✅ ~/report-cluster.txt"

echo
echo "Verifica:"
echo "   grep -E 'CVE-[0-9]+-[0-9]+' ~/report-image.txt | head -3"
echo "   grep -E 'AVD-' ~/report-config.txt | head -3"
echo "   head -30 ~/report-cluster.txt"
