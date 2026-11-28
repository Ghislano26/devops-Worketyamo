# Crossplane : premier composite

**Durée : ~35 minutes** (dont 3 à 5 minutes de téléchargement des paquets). Compétence travaillée : installer **Crossplane** avec Helm, ajouter un **provider**, définir une **API de plateforme** (XRD) et sa **Composition**, créer une **ressource composite** et vérifier la **ressource réelle**.

Rappel du [cours Crossplane](https://github.com/Ghislano26/devops-Worketyamo/blob/main/17-platform-engineering/cours/04-crossplane-control-plane.md) :

```text
XR « XWebApp boutique »  ──(Composition)──►  Object (Deployment)  ──provider-kubernetes──►  vrai Deployment
   image, replicas                           Object (Service)                               vrai Service
```

> 🔌 **Pas de compte cloud, donc `provider-kubernetes`.** Le provider **AWS** exige des identifiants (et créerait de vraies ressources facturables) : impossible sur Killercoda. `provider-kubernetes` joue le rôle d'un « faux cloud » : une `Object` Crossplane **crée un objet Kubernetes** dans ce cluster. Tous les mécanismes (provider, XRD, Composition, XR, réconciliation, statut) sont **identiques** à ceux d'une base RDS ou d'un bucket S3 ; seul le provider change. Pour AWS, le [défi bonus](https://github.com/Ghislano26/devops-Worketyamo/tree/main/17-platform-engineering/ateliers-killercoda/atelier-02-crossplane-premier-composite) suggère LocalStack.

> 🌐 **Réseau et versions** : le scénario installe **Crossplane `1.18.0`** (Helm, `charts.crossplane.io`) puis télécharge deux **paquets** depuis `xpkg.upbound.io` : `provider-kubernetes` `v0.15.0` et `function-patch-and-transform` `v0.7.0`. Ces versions sont **épinglées** : l'API de Crossplane **évolue** (la série 2.x change plusieurs mécanismes) ; ne remplacez pas ces versions sans lire la documentation.

Cet atelier s'exécute sur un **cluster Kubernetes d'un nœud, déjà prêt** :

```bash
kubectl get nodes
```{{exec}}
