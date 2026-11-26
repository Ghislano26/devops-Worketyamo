# Étape 1 : namespaces PID et UTS avec `unshare`

Un conteneur n'est qu'un **processus Linux isolé** (voir le [cours Conteneurs : namespaces et cgroups](https://github.com/Ghislano26/devops-Worketyamo/blob/main/04-linux-expert/cours/02-conteneurs-namespaces.md)). Observez d'abord vos namespaces :

```bash
ls -l /proc/$$/ns/
readlink /proc/$$/ns/pid /proc/1/ns/pid
```{{exec}}

## À vous de jouer

Lancez un shell dans de **nouveaux namespaces PID, montage et UTS** et, depuis l'intérieur, enregistrez des preuves dans des fichiers :

```bash
unshare --pid --fork --mount-proc --uts bash -c '
  echo $$ > /tmp/ns-pid.txt
  ps aux > /tmp/ns-ps.txt
  hostname prison
  hostname > /tmp/ns-host.txt
'
```{{exec}}

Analysez les résultats **depuis l'hôte** :

```bash
cat /tmp/ns-pid.txt          # le PID du shell DANS le namespace
cat /tmp/ns-ps.txt           # les seuls processus qu'il voyait
cat /tmp/ns-host.txt         # le nom d'hôte DANS le namespace
hostname                     # le nom d'hôte de l'hôte : inchangé
```{{exec}}

> Pourquoi le shell avait-il le PID **1** ? Dans un nouveau namespace PID, le premier processus est numéroté 1. Pourquoi `--mount-proc` ? `ps` lit `/proc` : sans lui, il afficherait encore les processus de l'hôte.

Cliquez sur **Vérifier**.
