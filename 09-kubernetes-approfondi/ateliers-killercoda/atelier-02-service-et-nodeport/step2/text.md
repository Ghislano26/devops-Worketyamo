# Étape 2 : ouvrir le Service vers l'extérieur du cluster

Un **NodePort** ouvre le **même port** (30000-32767) sur **chaque nœud** et le redirige vers le Service. Passez le Service `web` en NodePort :

```bash
kubectl patch svc web -p '{"spec":{"type":"NodePort"}}'
kubectl get svc web
```{{exec}}

Récupérez le port attribué (colonne `PORT(S)` : `80:3xxxx/TCP`) :

```bash
NODEPORT=$(kubectl get svc web -o jsonpath='{.spec.ports[0].nodePort}')
echo "NodePort = $NODEPORT"
```{{exec}}

Testez **depuis le nœud** (la machine du terminal) :

```bash
curl -s localhost:$NODEPORT | head -n 5
```{{exec}}

Essayez aussi avec l'IP du nœud :

```bash
NODE_IP=$(kubectl get node -o jsonpath='{.items[0].status.addresses[?(@.type=="InternalIP")].address}')
curl -s -o /dev/null -w "HTTP %{http_code}\n" http://$NODE_IP:$NODEPORT
```{{exec}}

## Pour comprendre

Regardez les règles créées par `kube-proxy` (DNAT, comme pour `docker -p`, voir le [module 06](https://github.com/Ghislano26/devops-Worketyamo/blob/main/06-reseaux-devops/cours/03-routage-et-nat.md)) :

```bash
iptables -t nat -S KUBE-NODEPORTS | head
```{{exec}}

## Fixer le port (facultatif)

Un manifeste déclaratif permet de choisir le `nodePort` :

```bash
cat <<'EOF' | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: web
spec:
  type: NodePort
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 80
      nodePort: 30080
EOF
curl -s -o /dev/null -w "HTTP %{http_code}\n" localhost:30080
```{{exec}}

## Questions

- Quelle différence entre `port`, `targetPort` et `nodePort` ? (Voir le [cours 03](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/cours/03-services-et-reseau-kubernetes.md).)
- Pourquoi un NodePort n'est-il pas idéal en production ? (Un port par service, IP des nœuds exposée : on préfère un **LoadBalancer** ou un **Ingress**.)

Cliquez sur **Vérifier** quand le NodePort répond.
