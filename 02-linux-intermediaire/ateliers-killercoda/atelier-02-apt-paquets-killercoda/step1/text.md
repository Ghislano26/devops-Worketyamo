# Étape 1 : installer et inspecter

Rafraîchissez l'index (ce n'est **pas** une mise à jour : voir le [cours APT](https://github.com/Ghislano26/devops-Worketyamo/blob/main/02-linux-intermediaire/cours/02-gestion-paquets.md)) :

```bash
apt-get update
```{{exec}}

Inspectez avant d'installer, puis installez **`jq`** (un outil de traitement JSON) :

```bash
apt-cache policy jq | head -n 4
apt-get install -y jq
jq --version
```{{exec}}

## À vous de jouer

À quel paquet appartient le fichier `/usr/bin/jq` ? Interrogez la base de `dpkg` et enregistrez la réponse dans `/tmp/jq-paquet.txt` :

```bash
dpkg -S /usr/bin/jq > /tmp/jq-paquet.txt
cat /tmp/jq-paquet.txt
dpkg -L jq | head -n 10
```{{exec}}

> `apt` est l'outil de haut niveau (dépôts, dépendances), `dpkg` l'outil de bas niveau (le paquet `.deb` installé). `dpkg -S` répond à « qui possède ce fichier ? », `dpkg -L` à « que contient ce paquet ? ».

Cliquez sur **Vérifier**.
