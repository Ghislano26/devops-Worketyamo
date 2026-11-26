# Docker : premiers pas

Bienvenue ! Dans cet atelier de 15 minutes, vous allez manipuler **de vrais conteneurs** dans un environnement Ubuntu prêt à l'emploi
(Docker est préinstallé) :

1. lancer un serveur **nginx** et l'interroger ;
2. constater qu'un conteneur est **éphémère**, puis rendre des données **persistantes** avec un **volume**.

Cet atelier met en pratique les cours [Architecture de Docker](https://github.com/Ghislano26/devops-Worketyamo/blob/main/08-docker-approfondi/cours/01-architecture-docker.md) et
[Réseau et stockage](https://github.com/Ghislano26/devops-Worketyamo/blob/main/08-docker-approfondi/cours/04-reseau-et-stockage-docker.md).

## Vérifions l'environnement

```bash
docker --version
```{{exec}}

```bash
docker info | grep -E "Server Version|Storage Driver|Cgroup Version|Default Runtime|Docker Root Dir"
```{{exec}}

Notez le **pilote de stockage** (`overlay2`), le **runtime** (`runc`) et la version de **cgroup**. Ce sont les composants vus dans le cours : `dockerd`, `containerd`, `runc`.

```bash
docker run --rm hello-world
```{{exec}}

Si le message « Hello from Docker! » s'affiche, tout est prêt.
