# ConfigMap, Secret et RBAC

Une même image doit tourner partout : seule la **configuration** change. Et chaque identité (humaine ou applicative) ne doit pouvoir faire que ce dont elle a besoin.

Dans cet atelier, vous allez :

1. créer un **ConfigMap** et un **Secret**, et les consommer dans un pod par **variables d'environnement** et par **fichiers montés** ;
2. créer un **ServiceAccount**, un **Role** (lecture des pods) et un **RoleBinding**, puis tester avec `kubectl auth can-i`.

Rappels des cours [Configuration et secrets](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/cours/05-configuration-et-secrets.md) et [Sécurité : RBAC](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/cours/07-securite-rbac-et-networkpolicies.md) :

- un Secret est en **base64, pas chiffré** : la protection vient du **RBAC**, du chiffrement d'etcd et d'une gestion externe des secrets ;
- le RBAC est **additif** : tout est refusé par défaut ; on accorde le **strict minimum** dans le **namespace** concerné.

Vérifions le cluster :

```bash
kubectl get nodes
```{{exec}}
