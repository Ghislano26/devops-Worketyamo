# Déploiement canary sur Kubernetes

**Durée : ~30 minutes.** Compétence travaillée : **déployer progressivement** une nouvelle version en limitant l'impact, mesurer la répartition du trafic et **promouvoir** le canari.

Rappel du [cours Stratégies de déploiement](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/07-strategies-de-deploiement.md) :

```text
Service (selector app=web)  ──►  app-v1 : 4 pods  (nginx 1.24, stable)   ~80 %
                            └──►  app-v2 : 1 pod   (nginx 1.25, canari)   ~20 %
```

## Vérifions le cluster

```bash
kubectl get nodes
kubectl get pods -A | head -n 5
```{{exec}}

Le nœud doit être `Ready`.
