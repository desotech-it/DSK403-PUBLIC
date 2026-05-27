#!/usr/bin/env bash
# Q08 break: crea un Secret 'demo' visibile in chiaro su etcd (cluster senza encryption-provider-config)
set -euo pipefail
kubectl create secret generic demo \
  --from-literal=password=ciaomondo123 \
  --dry-run=client -o yaml | kubectl apply -f -

echo
echo "✅ Secret 'demo' creato. Verifica che sia in chiaro in etcd dal control plane:"
echo "   docker exec dsk102-lab-08-control-plane sh -c 'ETCDCTL_API=3 etcdctl \\"
echo "     --endpoints=https://127.0.0.1:2379 \\"
echo "     --cacert=/etc/kubernetes/pki/etcd/ca.crt \\"
echo "     --cert=/etc/kubernetes/pki/etcd/server.crt \\"
echo "     --key=/etc/kubernetes/pki/etcd/server.key \\"
echo "     get /registry/secrets/default/demo' | strings | grep ciaomondo123"
