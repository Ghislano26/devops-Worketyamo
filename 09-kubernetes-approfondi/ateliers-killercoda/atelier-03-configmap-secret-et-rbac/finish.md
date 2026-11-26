# Bravo !

Vous avez :

- consommé un **ConfigMap** et un **Secret** en **variables** (figées au démarrage) et en **fichiers** (mis à jour) ;
- constaté qu'un Secret n'est qu'**encodé** en base64 ;
- appliqué le **moindre privilège** : un ServiceAccount qui peut **lire** les pods d'un namespace, sans pouvoir ni les supprimer, ni lire les secrets, ni sortir du namespace.

## Nettoyage

```bash
kubectl delete namespace atelier
```{{exec}}

## Pour aller plus loin

- Rendez le ConfigMap `immutable: true`, versionnez son nom (`app-config-v2`) et faites évoluer un Deployment pour qu'une mise à jour de configuration soit un vrai *rollout*.
- Créez un pod qui **utilise** le ServiceAccount `lecteur` (`serviceAccountName: lecteur`) et appelez l'API depuis le pod avec le jeton monté.
- Ajoutez un `securityContext` (`runAsNonRoot`, `readOnlyRootFilesystem`, `capabilities.drop: [ALL]`) et activez le Pod Security `restricted` sur le namespace.
- Écrivez une **NetworkPolicy** *default-deny* pour le namespace `atelier` (nécessite un CNI qui les applique).
- Retour au [module 09](https://github.com/Ghislano26/devops-Worketyamo/blob/main/09-kubernetes-approfondi/README.md).
