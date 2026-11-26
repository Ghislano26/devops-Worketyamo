# Bravo !

Vous avez **construit à la main** deux briques d'un conteneur : l'isolation (`unshare` : PID, montage, UTS) et la limitation de ressources (cgroup v2 : `memory.max`, `pids.max`, `cpu.max`). Docker et Kubernetes ne font rien d'autre, de façon industrialisée.

## Pour continuer

- Refaites le [**défi du jour**](https://github.com/Ghislano26/devops-Worketyamo/blob/main/04-linux-expert/ateliers/atelier-02-namespaces-cgroups.md) sur votre serveur : un service web dans son **propre namespace réseau** (`ip netns`, `veth`).
- Cochez la [checklist](https://github.com/Ghislano26/devops-Worketyamo/blob/main/04-linux-expert/CHECKLIST.md) du module 04.
- Suite du cursus : [Réseaux pour DevOps](https://github.com/Ghislano26/devops-Worketyamo/blob/main/06-reseaux-devops/README.md), puis [Docker approfondi](https://github.com/Ghislano26/devops-Worketyamo/blob/main/08-docker-approfondi/README.md).
