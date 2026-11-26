# Étape 2 : RBAC et moindre privilège

Créez une identité **`lecteur`** (ServiceAccount) qui peut **lire** les pods du namespace `atelier`, mais **rien d'autre** ([cours 07](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/cours/07-securite-rbac-et-networkpolicies.md)).

```bash
kubectl create serviceaccount lecteur -n atelier
kubectl create role pod-reader -n atelier --verb=get,list,watch --resource=pods
kubectl create rolebinding lecteur-pods -n atelier --role=pod-reader --serviceaccount=atelier:lecteur
```{{exec}}

Vérifiez ce que contiennent ces objets :

```bash
kubectl get role pod-reader -n atelier -o yaml | sed -n '/rules/,$p'
kubectl describe rolebinding lecteur-pods -n atelier
```{{exec}}

## Tester sans se connecter : `kubectl auth can-i`

Le drapeau `--as` fait **se faire passer** votre requête pour le ServiceAccount :

```bash
SA=system:serviceaccount:atelier:lecteur
kubectl auth can-i list pods   -n atelier --as=$SA
kubectl auth can-i get pods    -n atelier --as=$SA
kubectl auth can-i delete pods -n atelier --as=$SA
kubectl auth can-i list secrets -n atelier --as=$SA
kubectl auth can-i list pods   -n default --as=$SA
```{{exec}}

Résultat attendu : `yes`, `yes`, `no`, `no`, `no`. La permission est **limitée au namespace** `atelier` (un `Role`, pas un `ClusterRole`) et **aux verbes** de lecture.

Voyez l'ensemble de ses droits et faites une **vraie** requête avec l'identité du ServiceAccount :

```bash
kubectl auth can-i --list -n atelier --as=$SA
kubectl get pods -n atelier --as=$SA
kubectl delete pod demo -n atelier --as=$SA
```{{exec}}

La dernière commande doit échouer avec `Forbidden` : c'est le comportement voulu.

## Questions

- Pourquoi **ne pas** accorder `cluster-admin` « pour que ça marche » ? Quel serait le risque si le pod utilisant ce ServiceAccount était compromis ?
- Quel objet faudrait-il pour que le même droit s'applique **dans tous** les namespaces ? (`ClusterRole` + `ClusterRoleBinding`, à éviter sauf nécessité.)
- Pourquoi le droit `list` sur les **secrets** est-il si sensible ?

Cliquez sur **Vérifier** : `lecteur` doit pouvoir lister les pods mais pas les supprimer.
