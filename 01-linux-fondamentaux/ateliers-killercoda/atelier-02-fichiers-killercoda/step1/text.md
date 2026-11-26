# Étape 1 : créer l'arborescence `/tmp/devops`

Créez trois sous-dossiers **en une seule commande** (`-p` crée aussi les dossiers parents ; les accolades génèrent les trois noms) :

```bash
mkdir -p /tmp/devops/{config,logs,scripts}
ls /tmp/devops
```{{exec}}

Placez-y trois fichiers :

```bash
echo "port=8080" > /tmp/devops/config/app.conf
printf 'INFO demarrage\nERROR disque plein\n' > /tmp/devops/logs/app.log
printf '#!/usr/bin/env bash\necho deploiement\n' > /tmp/devops/scripts/deploy.sh
```{{exec}}

Vérifiez le résultat de deux façons :

```bash
find /tmp/devops
apt-get install -y tree >/dev/null 2>&1 && tree /tmp/devops
```{{exec}}

> `>` écrase le fichier, `>>` ajoute à la fin (voir le [cours 03](https://github.com/Ghislano26/devops-Worketyamo/blob/main/01-linux-fondamentaux/cours/03-navigation-commandes-base.md)). Pourquoi `mkdir -p` ? Sans lui, `mkdir` échoue si le dossier parent n'existe pas.

Cliquez sur **Vérifier**.
