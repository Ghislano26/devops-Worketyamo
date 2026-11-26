# Namespaces et cgroups

**Durée : ~10 minutes.** Compétence travaillée : comprendre ce qu'est réellement un conteneur, sans Docker.

Prérequis : le cours [Conteneurs : namespaces et cgroups](https://github.com/Ghislano26/devops-Worketyamo/blob/main/04-linux-expert/cours/02-conteneurs-namespaces.md).

```text
conteneur = processus  +  namespaces (ce qu'il VOIT)  +  cgroups (ce qu'il CONSOMME)
```

Listez les namespaces de la machine :

```bash
lsns | head -n 10
uname -r
```{{exec}}
