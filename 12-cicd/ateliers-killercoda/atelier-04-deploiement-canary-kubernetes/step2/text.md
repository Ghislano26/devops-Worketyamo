# Étape 2 : progresser par paliers, puis promouvoir

Si les métriques du canari sont bonnes, on **augmente sa part** puis on le **promeut** : la nouvelle version devient la version stable. Ici, on simule la décision « tout va bien ».

## Palier à 50 %

```bash
kubectl scale deployment app-v2 --replicas=2
kubectl scale deployment app-v1 --replicas=2
kubectl rollout status deployment/app-v2
kubectl get endpoints web
```{{exec}}

Mesurez à nouveau :

```bash
kubectl run client --rm -i --restart=Never --image=curlimages/curl --command -- \
  sh -c 'for i in $(seq 1 50); do curl -sI http://web | grep -i "^server"; done | sort | uniq -c' 2>/dev/null
```{{exec}}

La répartition est maintenant d'environ **moitié-moitié**.

## Promotion : 100 % sur la v2

On monte la v2 au nombre nominal de réplicas **avant** de réduire la v1 : à aucun moment le service ne manque de capacité (`maxUnavailable: 0` serait le réglage équivalent d'un rolling update).

```bash
kubectl scale deployment app-v2 --replicas=4
kubectl rollout status deployment/app-v2
kubectl scale deployment app-v1 --replicas=0
kubectl get pods -l app=web
kubectl get endpoints web
```{{exec}}

## Et si le canari avait été mauvais ?

Le **retour arrière** serait immédiat : `kubectl scale deployment app-v2 --replicas=0`. La v1 n'a jamais cessé de servir : c'est la force du canari ([cours 7, rollback](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/07-strategies-de-deploiement.md)).

Vérifiez que tout le trafic va à la v2 :

```bash
kubectl run client --rm -i --restart=Never --image=curlimages/curl --command -- \
  sh -c 'for i in $(seq 1 50); do curl -sI http://web | grep -i "^server"; done | sort | uniq -c' 2>/dev/null
```{{exec}}

Cliquez sur **Vérifier**.
