# Étape 1 : se repérer et chercher

Où êtes-vous ? Qui êtes-vous ? Sur quelle machine ?

```bash
pwd
whoami
hostname
```{{exec}}

Rendez-vous dans `/var/log` (le dossier des journaux, voir le [cours Système de fichiers](https://github.com/Ghislano26/devops-Worketyamo/blob/main/01-linux-fondamentaux/cours/02-systeme-fichiers.md)) et listez son contenu en format long, fichiers cachés inclus :

```bash
cd /var/log
pwd
ls -la | head -n 15
```{{exec}}

Les plus gros fichiers d'abord, puis les plus récents :

```bash
ls -lS | head -n 5
ls -lt | head -n 5
```{{exec}}

## À vous de jouer

Avec **`find`**, retrouvez le chemin absolu du fichier **`dpkg.log`** (journal des installations de paquets) et enregistrez-le dans `/tmp/chemin-dpkg.txt` :

```bash
find /var/log -name dpkg.log > /tmp/chemin-dpkg.txt
cat /tmp/chemin-dpkg.txt
```{{exec}}

> Pourquoi `/var/log` en premier argument de `find` ? C'est le **point de départ** de la recherche : `find` descend récursivement depuis ce dossier.

Revenez ensuite dans votre dossier personnel avec `cd` (sans argument), puis cliquez sur **Vérifier**.
