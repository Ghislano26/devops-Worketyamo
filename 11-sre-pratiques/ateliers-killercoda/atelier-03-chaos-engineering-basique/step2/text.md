# Étape 2 : l'expérience

## A. Tuer un pod (la panne la plus simple)

Dans un **second terminal** (ou en arrière-plan), lancez une boucle de requêtes pour **observer l'effet** pendant l'expérience :

```bash
kubectl run sonde --restart=Never --image=busybox:1.36 -- sh -c \
  'while true; do wget -q -O /dev/null -T 2 http://web && echo "$(date +%T) OK" || echo "$(date +%T) ECHEC"; sleep 0.5; done'
```{{exec}}

Choisissez **un** pod, **notez son nom** dans `~/chaos/pod-supprime.txt`, puis supprimez-le :

```bash
POD=$(kubectl get pods -l app=web -o name | head -n 1 | cut -d/ -f2)
echo "$POD" > ~/chaos/pod-supprime.txt
echo "Pod ciblé : $POD"
kubectl delete pod "$POD"
kubectl get pods -l app=web
```{{exec}}

Observez la **réparation automatique** : le ReplicaSet recrée un pod pour revenir à 3 réplicas ; regardez les évènements et la sonde :

```bash
kubectl rollout status deployment/web
kubectl get pods -l app=web
kubectl get events --sort-by=.lastTimestamp | tail -n 8
kubectl logs sonde | tail -n 12
kubectl logs sonde | grep -c ECHEC
```{{exec}}

> Hypothèse confirmée ? Il peut y avoir **0 ou quelques échecs** pendant la suppression : un pod en `Terminating` reçoit encore du trafic un court instant (c'est une vraie leçon : on corrige avec une `readinessProbe` et un `preStop`).

## B. Injecter de la latence réseau (facultatif mais instructif)

On ajoute **300 ms** de délai sur l'interface d'un pod avec `tc netem`, **depuis le nœud** (vous êtes sur le nœud) en entrant dans l'espace de noms réseau du conteneur :

```bash
apt-get install -y -qq jq iproute2 >/dev/null 2>&1
modprobe sch_netem 2>/dev/null || echo "(sch_netem non disponible : voir la remarque ci-dessous)"
POD=$(kubectl get pods -l app=web -o name | head -n 1 | cut -d/ -f2)
CID=$(crictl ps --name nginx -q --label io.kubernetes.pod.name=$POD | head -n 1)
PID=$(crictl inspect "$CID" | jq -r '.info.pid')
echo "pod=$POD  pid=$PID"
IP=$(kubectl get pod "$POD" -o jsonpath='{.status.podIP}')
echo "avant : $(curl -s -o /dev/null -w '%{time_total}s' http://$IP)"
nsenter -t "$PID" -n tc qdisc add dev eth0 root netem delay 300ms
echo "après : $(curl -s -o /dev/null -w '%{time_total}s' http://$IP)"
```{{exec}}

Les requêtes vers ce pod doivent prendre **~0,3 s de plus**. Via le Service, un tiers des requêtes seulement est ralenti (un pod sur trois) : observez la **latence de queue** avec la sonde. Puis **retirez la perturbation** (retour arrière) :

```bash
nsenter -t "$PID" -n tc qdisc del dev eth0 root
echo "retour arrière : $(curl -s -o /dev/null -w '%{time_total}s' http://$IP)"
```{{exec}}

> Si `tc` échoue (module `sch_netem` absent sur cette image), ce n'est pas bloquant : l'**exigence de validation** porte sur la partie A. Dans un cluster réel, l'outil **Chaos Mesh** (`NetworkChaos`) fait la même chose de façon déclarative.

## Nettoyage de la sonde

```bash
kubectl delete pod sonde --ignore-not-found
kubectl scale deployment web --replicas=3
kubectl rollout status deployment/web
```{{exec}}

## Questions

- Qu'avez-vous appris sur la **détection** ? (Aurait-on vu la perte d'un pod sans la sonde ?)
- Quel **pattern de fiabilité** réduit l'impact d'un pod lent ? (Timeouts, retries avec jitter, circuit breaker : [cours 07](https://github.com/Ghislano26/devops-Worketyamo/blob/main/11-sre-pratiques/cours/07-patterns-fiabilite.md).)
- Pourquoi **ne pas** lancer cette expérience si le budget d'erreur est épuisé ? (Le chaos dépense du budget.)

Cliquez sur **Vérifier** : le pod supprimé doit avoir été **remplacé** et le Deployment être revenu à **3 réplicas**.
