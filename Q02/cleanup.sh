#!/usr/bin/env bash
# Q02 cleanup: rimuove la flag --anonymous-auth=false (torna al default true)
set -uo pipefail
CTL="${CTL:-dsk102-lab-08-control-plane}"
docker exec "$CTL" sed -i '\|--anonymous-auth=|d' /etc/kubernetes/manifests/kube-apiserver.yaml
echo "✅ Q02 cleanup completato (--anonymous-auth rimossa dal manifest)."
