#!/usr/bin/env bash
# Q01 fix: applica allow-dns-egress + allow-https-egress senza toccare default-deny.
#
# Note CNI: alcune implementazioni (kindnet incluso) non onorano il combinato
# namespaceSelector+podSelector per egress quando il client parla con un
# Service ClusterIP (la regola viene valutata contro la ClusterIP, non contro
# il pod backend dopo DNAT). Per questo qui apriamo la porta 53 verso QUALSIASI
# destinazione: è funzionale ovunque (kindnet, Calico, Cilium...).
#
# Per l'esame CKS la versione più stringente (con namespaceSelector+podSelector
# verso kube-system / k8s-app=kube-dns) è quella corretta -- viene mostrata in
# soluzioni/Q01.md del repo DSK403 con i dettagli del perche'.
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
  - ports:
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
echo "   kubectl -n prod exec test -- nslookup kubernetes.io                # OK"
echo "   kubectl -n prod exec test -- curl -sI -m 5 https://kubernetes.io   # HTTP 2xx/3xx"
