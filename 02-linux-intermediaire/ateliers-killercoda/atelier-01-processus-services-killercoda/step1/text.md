# Étape 1 : un processus, un PID, un signal

Lancez un processus en arrière-plan et mémorisez son PID (`$!`) :

```bash
sleep 600 &
echo $! > /tmp/sleep.pid
cat /tmp/sleep.pid
```{{exec}}

Retrouvez-le de plusieurs façons (voir le [cours Processus et services](https://github.com/Ghislano26/devops-Worketyamo/blob/main/02-linux-intermediaire/cours/01-processus-services.md)) :

```bash
ps -o pid,ppid,stat,cmd -p "$(cat /tmp/sleep.pid)"
pgrep -a sleep
pstree -p | head -n 12
```{{exec}}

## À vous de jouer

Arrêtez-le **proprement** avec `SIGTERM` (15), le signal par défaut de `kill`, puis prouvez qu'il n'existe plus :

```bash
kill "$(cat /tmp/sleep.pid)"
sleep 1
ps -p "$(cat /tmp/sleep.pid)" || echo "le processus n'existe plus"
```{{exec}}

> Pourquoi `SIGTERM` avant `SIGKILL` (`kill -9`) ? `SIGTERM` laisse au processus le temps de nettoyer ; `SIGKILL` le tue sans préavis et ne peut pas être intercepté.

Cliquez sur **Vérifier**.
