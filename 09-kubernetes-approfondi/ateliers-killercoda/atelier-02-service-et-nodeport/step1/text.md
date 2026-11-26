# Étape 1 : un Service pour joindre les pods

Les pods sont éphémères et changent d'IP : un **Service** fournit une **IP virtuelle stable** et un **nom DNS** devant eux ([cours 03](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/cours/03-services-et-reseau-kubernetes.md)).

Déployez nginx (2 réplicas) :

```bash
kubectl create deployment web --image=nginx:1.27 --replicas=2
kubectl rollout status deployment/web
```{{exec}}

Créez un Service **ClusterIP** nommé `web` (type par défaut) :

```bash
kubectl expose deployment web --port=80 --target-port=80
kubectl get svc web
kubectl get endpoints web
```{{exec}}

La colonne **ENDPOINTS** liste les **IP des pods prêts** : c'est la première chose à vérifier quand un Service ne répond pas.

## Tester depuis l'intérieur du cluster

Un ClusterIP n'est joignable que **dans** le cluster. Lancez un pod **busybox temporaire** (supprimé à la sortie) pour interroger le Service par son **nom DNS** :

```bash
kubectl run test --rm -it --restart=Never --image=busybox:1.36 -- wget -qO- http://web
```{{exec}}

La page « Welcome to nginx! » doit s'afficher. Regardez aussi comment le pod résout le nom :

```bash
kubectl run dns --rm -it --restart=Never --image=busybox:1.36 -- sh -c 'cat /etc/resolv.conf; nslookup web'
```{{exec}}

> Le nom complet est `web.default.svc.cluster.local` ; `web` suffit car `/etc/resolv.conf` contient `search default.svc.cluster.local …`.

## Questions

- Quelle IP voyez-vous dans `nslookup web` ? C'est la **ClusterIP** : aucune interface ne l'utilise, `kube-proxy` la traduit en l'IP d'un pod par des règles iptables (essayez `iptables -t nat -S | grep web`).
- Que montre `kubectl get endpoints web` si vous scalez à 0 (`kubectl scale deployment web --replicas=0`) ? Remettez ensuite 2 réplicas.

Cliquez sur **Vérifier** quand le Service `web` existe et répond.
