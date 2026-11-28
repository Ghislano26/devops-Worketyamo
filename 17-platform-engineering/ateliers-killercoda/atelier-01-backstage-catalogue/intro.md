# Backstage : un catalogue logiciel

**Durée : ~35 minutes** (dont 5 à 10 minutes de démarrage). Compétence travaillée : déployer **Backstage** avec Helm, décrire des services dans un **`catalog-info.yaml`**, les voir apparaître dans le **catalogue** avec leurs **relations**, puis **ajouter une entité**.

Rappel du [cours Backstage](https://github.com/Ghislano26/devops-Worketyamo/blob/main/17-platform-engineering/cours/03-backstage-portal.md) :

```text
catalog-info.yaml (Group, System, Component)  ──►  Backstage (catalogue)  ──►  entités + relations
   ownedBy : boutique-api → équipe-boutique        partOf : boutique-api → système boutique
   dependsOn : boutique-web → boutique-api
```

> ⚠️ **Backstage est lourd.** Le chart Helm déploie l'**image de démonstration** officielle (plusieurs centaines de Mo, démarrage de **1 à 3 minutes**, mémoire importante). Il n'est pas prévu pour la production : en vrai, on construit **sa propre** image à partir de `create-app` ([cours 3](https://github.com/Ghislano26/devops-Worketyamo/blob/main/17-platform-engineering/cours/03-backstage-portal.md)). Ici, la **base de données est en mémoire** (SQLite) : **tout est perdu** si le pod redémarre, d'où le **ConfigMap** qui conserve nos fichiers de catalogue. La version du chart n'est **pas épinglée** (voir `helm list` pour la noter).

> 🌐 **Réseau** : `backstage.github.io` (chart), `ghcr.io` (image), `raw.githubusercontent.com` (Helm).

Cet atelier s'exécute sur un **cluster Kubernetes d'un nœud, déjà prêt** :

```bash
kubectl get nodes
```{{exec}}
