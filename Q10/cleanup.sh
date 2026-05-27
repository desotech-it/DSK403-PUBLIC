#!/usr/bin/env bash
set -uo pipefail
CTL="${CTL:-dsk102-lab-08-control-plane}"
docker exec "$CTL" sed -i '\|--admission-control-config-file=|d' /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null || true
docker exec "$CTL" sed -i '/--enable-admission-plugins=/ s|,ImagePolicyWebhook||g' /etc/kubernetes/manifests/kube-apiserver.yaml 2>/dev/null || true
docker exec "$CTL" rm -rf /etc/kubernetes/admission 2>/dev/null || true
kubectl delete deploy image-scanner -n default --ignore-not-found
kubectl delete svc image-scanner -n default --ignore-not-found
echo "✅ Q10 cleanup completato."
