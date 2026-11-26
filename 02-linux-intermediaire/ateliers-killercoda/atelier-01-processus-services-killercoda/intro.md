# Processus et services systemd

**Durée : ~10 minutes.** Compétence travaillée : repérer, arrêter et superviser des processus, puis déployer un **service** résistant aux pannes.

Prérequis : le cours [Processus, signaux et services systemd](https://github.com/Ghislano26/devops-Worketyamo/blob/main/02-linux-intermediaire/cours/01-processus-services.md).

```bash
ps -p 1 -o pid,cmd
systemctl --version | head -n 1
uptime
```{{exec}}

Le processus n°1 est **systemd**, ancêtre de tous les autres.
