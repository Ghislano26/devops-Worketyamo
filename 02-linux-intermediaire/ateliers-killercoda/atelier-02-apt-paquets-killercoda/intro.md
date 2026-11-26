# Gérer les paquets avec APT

**Durée : ~10 minutes.** Compétence travaillée : installer, inspecter et supprimer proprement des logiciels.

Prérequis : le cours [Gestion des paquets avec APT](https://github.com/Ghislano26/devops-Worketyamo/blob/main/02-linux-intermediaire/cours/02-gestion-paquets.md).

```bash
lsb_release -ds
cat /etc/apt/sources.list.d/ubuntu.sources | head -n 8
```{{exec}}

Repérez le nom de code de la version (`noble` pour Ubuntu 24.04) et les composants `main`, `universe`.
