# Docker Compose et réseau personnalisé

Dans cet atelier, vous allez décrire une petite pile (un **backend** et un **Redis**) dans un fichier `compose.yaml`, la placer sur un **réseau
personnalisé**, vérifier la **résolution DNS interne**, puis **publier** un port.

Cet atelier met en pratique le [cours Réseau et stockage](https://github.com/Ghislano26/devops-Worketyamo/blob/main/08-docker-approfondi/cours/04-reseau-et-stockage-docker.md) (réseaux utilisateur, DNS embarqué, publication de ports) et le [cours Compose](https://github.com/Ghislano26/devops-Worketyamo/blob/main/08-docker-approfondi/cours/05-docker-compose.md)
(`depends_on` avec `healthcheck`).

Vérifions que Compose est disponible :

```bash
docker compose version
```{{exec}}

> Si la commande n'est pas trouvée : `apt-get update && apt-get install -y docker-compose-v2` (ou `docker-compose-plugin` selon l'image).
