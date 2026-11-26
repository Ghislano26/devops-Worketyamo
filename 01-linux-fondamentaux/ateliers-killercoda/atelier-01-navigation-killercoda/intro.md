# Naviguer et s'aider soi-même

**Durée : ~10 minutes.** Compétence travaillée : se repérer dans l'arborescence Linux et trouver de l'aide **sans interface graphique**.

Cet atelier accompagne le module 01 du [parcours Linux](https://github.com/Ghislano26/devops-Worketyamo/blob/main/01-linux-fondamentaux/PARCOURS.md) : lisez d'abord les cours
[Introduction](https://github.com/Ghislano26/devops-Worketyamo/blob/main/01-linux-fondamentaux/cours/01-introduction-linux.md) et [Système de fichiers](https://github.com/Ghislano26/devops-Worketyamo/blob/main/01-linux-fondamentaux/cours/02-systeme-fichiers.md).

Vous disposez d'un vrai serveur Ubuntu (accès **root**). Pas de risque : l'environnement disparaît à la fin de la session.

Commençons par faire connaissance avec la machine :

```bash
pwd
whoami
cat /etc/os-release | head -n 3
```{{exec}}
