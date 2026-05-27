#!/usr/bin/env bash
# Q01 fix: applica allow-dns-egress + allow-https-egress senza toccare default-deny
set -euo pipefail

F=$(mktemp --suffix=.yaml)
cat <<'YAML' >"$F"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: prod
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
YAML
kubectl apply -f "$F"

cat <<'YAML' >"$F"
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-https-egress
  namespace: prod
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
        except:
        - 169.254.0.0/16
    ports:
    - protocol: TCP
      port: 443
YAML
kubectl apply -f "$F"
rm -f "$F"

echo
echo "✅ Fix applicata. Verifica:"
echo "   kubectl -n prod exec test -- nslookup kubernetes.io      # OK"
echo "   kubectl -n prod exec test -- curl -sI -m 5 https://kubernetes.io   # HTTP 2xx/3xx"
