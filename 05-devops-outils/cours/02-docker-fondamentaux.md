# Docker : les fondamentaux

## Pourquoi ce cours ?

« Ça marche sur ma machine ! » : la phrase la plus coûteuse de l'informatique. Une application dépend d'un
système, de bibliothèques, de versions précises. **Docker** empaquète l'application **et son environnement** dans une
**image** qui s'exécute à l'identique partout : poste du développeur, serveur de test, production. Fort de ce que
vous avez appris sur les [namespaces et cgroups](../../04-linux-expert/cours/02-conteneurs-namespaces.md), vous savez
déjà *comment* cela fonctionne ; voici l'outil qui l'industrialise.

## 1. Vocabulaire

| Terme | Définition |
|---|---|
| **Image** | Modèle en lecture seule, composé de couches (système + application) |
| **Conteneur** | Instance en cours d'exécution d'une image (un processus isolé) |
| **Dockerfile** | Fichier texte décrivant comment construire une image |
| **Registre** (*registry*) | Dépôt d'images : Docker Hub, GitHub Container Registry |
| **Volume** | Stockage persistant géré par Docker |
| **Réseau** | Réseau virtuel reliant des conteneurs |

```text
Dockerfile ──docker build──► Image ──docker run──► Conteneur
                               │
                          docker push ──► Registre ◄── docker pull
```

> 📌 **À retenir** : une **image** est à un **conteneur** ce qu'un **programme** est à un **processus**.

## 2. Installation sur Ubuntu 24.04

Dépôt officiel Docker (méthode recommandée) :

```bash
sudo apt update
sudo apt install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl enable --now docker
docker --version
sudo docker run --rm hello-world
```

Pour utiliser Docker sans `sudo` :

```bash
sudo usermod -aG docker "$USER"
newgrp docker             # ou reconnectez-vous
docker ps
```

> ⚠️ **Attention** : appartenir au groupe `docker` équivaut à avoir **root** sur la machine (on peut monter `/` dans un conteneur). Ne l'accordez qu'aux personnes de confiance ; envisagez Docker *rootless* ou Podman.

Alternative rapide : `sudo apt install -y docker.io` (paquet Ubuntu, plus ancien).

## 3. Premiers pas : exécuter des conteneurs

```bash
docker run hello-world                         # télécharge l'image puis exécute
docker run -it ubuntu:24.04 bash               # shell interactif (-i -t)
docker run -d --name web -p 8080:80 nginx      # arrière-plan (-d), port 8080 hôte → 80 conteneur
curl -I http://localhost:8080
docker ps                                      # conteneurs en cours
docker ps -a                                   # tous, y compris arrêtés
docker logs web                                # journaux (sortie standard du conteneur)
docker logs -f --tail 20 web
docker exec -it web bash                       # shell dans un conteneur en cours
docker stop web                                # SIGTERM puis SIGKILL après 10 s
docker start web
docker rm web                                  # supprime (ajoutez -f si en cours)
docker run --rm alpine echo "je disparais"     # --rm : supprimé à la fin
```

Options courantes de `docker run` :

| Option | Effet |
|---|---|
| `-d` | Arrière-plan |
| `-it` | Mode interactif avec terminal |
| `--name` | Nom du conteneur |
| `-p hôte:conteneur` | Publie un port |
| `-v source:destination` | Monte un volume ou un dossier |
| `-e VAR=valeur` | Variable d'environnement |
| `--rm` | Supprime à l'arrêt |
| `--memory 256m --cpus 0.5` | Limites (cgroups) |
| `--restart unless-stopped` | Redémarrage automatique |
| `--read-only`, `--user 1000` | Durcissement |

## 4. Les images

```bash
docker images                          # images locales
docker pull python:3.12-slim
docker search nginx
docker inspect nginx                   # métadonnées JSON
docker history nginx                   # couches et leur taille
docker rmi nginx                       # supprime une image
docker image prune                     # supprime les images orphelines
docker system df                       # espace utilisé
docker system prune                    # nettoyage global (attention)
```

Une image est un **empilement de couches** (OverlayFS) identifiées par une empreinte. Les couches communes sont **partagées** entre images.

**Tags** : `nginx:1.27`, `ubuntu:24.04`, `python:3.12-slim`. `latest` n'est qu'une étiquette par défaut : **évitez-la** en production, car elle change dans le temps.

| Variante | Taille | Usage |
|---|---|---|
| `ubuntu`, `debian` | ~30–80 Mo | Généraliste |
| `-slim` | ~ 50 Mo | Allégée |
| `alpine` | ~ 5 Mo | Minimale (musl libc : compatibilité parfois délicate) |
| `distroless` | minimale, sans shell | Production durcie |

## 5. Le Dockerfile

```dockerfile
# Image de base
FROM python:3.12-slim

# Métadonnées
LABEL maintainer="equipe@kamer-logistics.example"

# Répertoire de travail
WORKDIR /app

# Copier d'abord les dépendances pour profiter du cache
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Puis le code
COPY . .

# Utilisateur non privilégié
RUN useradd -r -u 10001 appuser
USER appuser

# Port documenté (n'ouvre rien à lui seul)
EXPOSE 8000

# Commande par défaut
CMD ["python", "app.py"]
```

| Instruction | Rôle |
|---|---|
| `FROM` | Image de départ (obligatoire, première instruction) |
| `RUN` | Exécute une commande **à la construction** (crée une couche) |
| `COPY` / `ADD` | Copie des fichiers (préférez `COPY`) |
| `WORKDIR` | Définit le dossier courant |
| `ENV` | Variable d'environnement |
| `ARG` | Variable disponible seulement à la construction |
| `EXPOSE` | Documente le port |
| `USER` | Utilisateur d'exécution |
| `ENTRYPOINT` | Programme fixe du conteneur |
| `CMD` | Commande/arguments **par défaut** (remplaçables) |
| `HEALTHCHECK` | Sonde de santé |

### `CMD` vs `ENTRYPOINT` ; forme *exec* vs *shell*

- **Forme exec** (recommandée) : `CMD ["python", "app.py"]` — le programme est le PID 1 et reçoit directement les signaux (`SIGTERM`).
- **Forme shell** : `CMD python app.py` — lancé via `/bin/sh -c`, les signaux n'atteignent pas l'application.

### Construction

```bash
docker build -t kamer/api:1.0 .
docker build -t kamer/api:1.0 -f Dockerfile.prod .
docker run -d -p 8000:8000 kamer/api:1.0
```

### Le cache de construction

Docker réutilise une couche tant que l'instruction **et tout ce qui précède** sont identiques. Placez donc **ce qui change rarement en premier** (dépendances) et **ce qui change souvent en dernier** (code).

### `.dockerignore`

```text
.git
*.log
node_modules
__pycache__
.env
```

Il réduit le contexte de construction et évite de fuiter des secrets dans l'image.

### Construction multi-étapes (*multi-stage*)

```dockerfile
# Étape 1 : compilation
FROM golang:1.23 AS build
WORKDIR /src
COPY . .
RUN CGO_ENABLED=0 go build -o /bin/app .

# Étape 2 : image finale minimale
FROM gcr.io/distroless/static-debian12
COPY --from=build /bin/app /app
USER nonroot
ENTRYPOINT ["/app"]
```

L'image finale ne contient ni compilateur ni sources : plus **légère** et avec une **surface d'attaque réduite**.

## 6. Persistance : volumes et montages

Le système de fichiers d'un conteneur est **éphémère** : sa couche d'écriture disparaît avec lui.

```bash
docker volume create donnees
docker run -d --name db -v donnees:/var/lib/postgresql/data -e POSTGRES_PASSWORD=secret postgres:16
docker run --rm -v "$PWD":/work -w /work alpine ls    # montage de dossier (bind mount)
docker volume ls
docker volume inspect donnees        # emplacement : /var/lib/docker/volumes/...
```

| Type | Syntaxe | Usage |
|---|---|---|
| **Volume nommé** | `-v donnees:/chemin` | Données persistantes gérées par Docker |
| **Bind mount** | `-v /hôte:/chemin` | Partager du code, de la configuration |
| **tmpfs** | `--tmpfs /tmp` | Données temporaires en mémoire |

## 7. Réseau

```bash
docker network ls
docker network create reseau-app
docker run -d --name api --network reseau-app kamer/api:1.0
docker run --rm --network reseau-app curlimages/curl http://api:8000    # résolution par nom !
docker network inspect reseau-app
```

Par défaut, les conteneurs sont reliés au pont `docker0` (172.17.0.0/16). Sur un **réseau défini par l'utilisateur**, Docker fournit une **résolution DNS par nom de conteneur**. `-p` crée une règle NAT (iptables/nftables) de l'hôte vers le conteneur.

## 8. Docker Compose : plusieurs services

```yaml
# compose.yaml
services:
  web:
    build: .
    ports:
      - "8000:8000"
    environment:
      DATABASE_URL: postgres://app:${DB_PASSWORD}@db:5432/app
    depends_on:
      db:
        condition: service_healthy
    restart: unless-stopped

  db:
    image: postgres:16
    environment:
      POSTGRES_USER: app
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: app
    volumes:
      - donnees:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U app"]
      interval: 5s
      retries: 5

volumes:
  donnees:
```

```bash
echo "DB_PASSWORD=changeme" > .env     # .env ne doit PAS être commité
docker compose up -d
docker compose ps
docker compose logs -f web
docker compose exec db psql -U app
docker compose down                    # arrête et supprime (-v : supprime aussi les volumes)
```

## 9. Sécurité : les bons réflexes

1. **Image officielle**, version **fixée**, mise à jour régulière.
2. **Utilisateur non-root** (`USER`).
3. **Aucun secret dans l'image** (ni `ENV`, ni `COPY .env`) : variables à l'exécution, *secrets* Docker/Kubernetes.
4. **Système de fichiers en lecture seule** (`--read-only`) et `--cap-drop ALL`.
5. **Limiter les ressources** (`--memory`, `--cpus`, `--pids-limit`).
6. **Scanner** les images : `docker scout cves <image>` ou `trivy image <image>`.
7. N'utilisez pas `--privileged` ; ne montez pas `/var/run/docker.sock`.

```bash
docker run -d --read-only --cap-drop ALL --security-opt no-new-privileges \
  --memory 128m --pids-limit 100 --user 10001 kamer/api:1.0
```

## 10. Diagnostic

```bash
docker logs <conteneur>
docker inspect -f '{{.State.ExitCode}} {{.State.OOMKilled}}' <conteneur>
docker stats --no-stream             # CPU/mémoire en direct
docker top <conteneur>               # processus
docker events                        # flux d'évènements
docker diff <conteneur>              # fichiers modifiés par rapport à l'image
journalctl -u docker -n 50           # journaux du démon
```

> 💡 **Conseil** : au quotidien, `docker ps -a`, `docker logs`, `docker exec -it` et `docker inspect` résolvent 90 % des diagnostics. Lancez toujours vos essais avec `--rm` pour ne pas accumuler de conteneurs arrêtés.

## Résumé

- **Image** (modèle en couches) → **conteneur** (processus isolé) ; construit à partir d'un **Dockerfile**.
- `docker run/ps/logs/exec/stop/rm` ; `docker build`, `docker push/pull`.
- Dockerfile : cache (dépendances d'abord), forme *exec*, `USER` non-root, **multi-stage**, `.dockerignore`.
- Les conteneurs sont éphémères : **volumes** pour les données ; **réseaux utilisateur** pour la résolution par nom.
- **Compose** décrit des applications multi-services.
- Sécurité : non-root, pas de secrets dans l'image, ressources limitées, images scannées.

## Pour aller plus loin

- Documentation officielle : <https://docs.docker.com>, `docker --help`.
- Podman, Buildah, `containerd`, **Kubernetes** (orchestration à grande échelle).
- OCI, signature d'images (cosign), registres privés.
- Atelier associé : [Premier Dockerfile](../ateliers/atelier-02-premier-dockerfile.md).
- Cours suivant : [Principes du CI/CD](03-ci-cd-principes.md).
