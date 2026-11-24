# Atelier 02 — Votre premier Dockerfile

## 🎯 Objectifs

- Installer Docker sur Ubuntu 24.04 et lancer des conteneurs.
- Écrire un `Dockerfile`, construire et exécuter une image.
- Comprendre le cache de construction, les volumes, les réseaux et Compose.
- Appliquer des réflexes de sécurité (utilisateur non-root, ressources limitées).

## 📋 Prérequis

- Atelier [01 — Git](atelier-01-git-branches.md) terminé.
- Cours lu : [Docker, fondamentaux](../cours/02-docker-fondamentaux.md). Idéalement aussi : [Conteneurs et namespaces](../../04-linux-expert/cours/02-conteneurs-namespaces.md).
- Accès Internet ; 10 Go de disque libre ; snapshot de la VM pris.

## 🧪 Scénario

*Kamer Logistics* possède une petite API de suivi de colis (Python). Aujourd'hui, elle s'installe « à la main » sur
chaque serveur et ne fonctionne pas partout. Vous allez la **conteneuriser** : image reproductible, exécution
sécurisée, persistance des données, puis orchestration avec une base Redis via Compose.

## Étapes

### Étape 1 — Installer Docker

Suivez la procédure du cours (section « Installation sur Ubuntu 24.04 ») ou, pour aller vite :

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
newgrp docker
docker --version
docker run --rm hello-world
```

> ❓ **Question 1** : Quelles étapes Docker a-t-il effectuées pour afficher le message de `hello-world` ? *(Lisez le texte affiché.)*

### Étape 2 — Découvrir les conteneurs

```bash
docker run -d --name web -p 8080:80 nginx:1.27
docker ps
curl -sI http://localhost:8080 | head -1
docker logs web | tail -3
docker exec web nginx -v
docker stop web && docker rm web
docker run --rm -it ubuntu:24.04 bash -c 'cat /etc/os-release | head -2; ps aux; hostname'
```

> ❓ **Question 2** : Dans le dernier conteneur, combien de processus voyez-vous ? Quel namespace l'explique ? *(Cours 04 : PID namespace.)*

### Étape 3 — Écrire l'application

```bash
mkdir -p ~/atelier-docker/api && cd ~/atelier-docker/api
cat > app.py <<'EOF'
"""API de suivi de colis (atelier Docker)."""
import json
import os
import socket
from http.server import BaseHTTPRequestHandler, HTTPServer

PORT = int(os.environ.get("PORT", "8000"))
COMPTEUR = os.environ.get("FICHIER_COMPTEUR", "/data/compteur.txt")


def incrementer():
    try:
        os.makedirs(os.path.dirname(COMPTEUR), exist_ok=True)
        try:
            with open(COMPTEUR) as f:
                n = int(f.read().strip() or 0)
        except FileNotFoundError:
            n = 0
        n += 1
        with open(COMPTEUR, "w") as f:
            f.write(str(n))
        return n
    except OSError as e:
        return f"erreur: {e}"


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/sante":
            corps, code = {"statut": "ok"}, 200
        else:
            corps = {"colis": "KL-1042", "statut": "en transit",
                     "conteneur": socket.gethostname(), "visites": incrementer()}
            code = 200
        data = json.dumps(corps).encode()
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(data + b"\n")


if __name__ == "__main__":
    print(f"Écoute sur le port {PORT}", flush=True)
    HTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
EOF
python3 app.py &
sleep 1; curl -s localhost:8000; kill %1
```

*(L'application n'a besoin que de la bibliothèque standard Python : pas de `requirements.txt`.)*

### Étape 4 — Premier Dockerfile (naïf)

```bash
cat > Dockerfile <<'EOF'
FROM ubuntu:24.04
RUN apt-get update && apt-get install -y python3
COPY . /app
WORKDIR /app
CMD python3 app.py
EOF
docker build -t kamer/api:naif .
docker images kamer/api
docker run -d --name api1 -p 8000:8000 kamer/api:naif
curl -s localhost:8000
docker logs api1
docker stop api1 && docker rm api1
```

> ❓ **Question 3** : Notez la taille de l'image. Que pensez-vous de `CMD python3 app.py` (forme shell) ? Qui est le PID 1 dans le conteneur ? (`docker run --rm kamer/api:naif ps` n'est pas disponible ; utilisez `docker exec api1 cat /proc/1/cmdline` sur un conteneur lancé.)

### Étape 5 — Dockerfile amélioré

```bash
cat > .dockerignore <<'EOF'
.git
*.log
__pycache__
.env
Dockerfile
EOF

cat > Dockerfile <<'EOF'
FROM python:3.12-slim

LABEL maintainer="equipe@kamer-logistics.example"

# Utilisateur non privilégié
RUN useradd --system --uid 10001 --no-create-home appuser \
 && mkdir /data && chown appuser /data

WORKDIR /app
COPY app.py .

ENV PORT=8000
EXPOSE 8000
USER appuser

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request,sys; sys.exit(0 if urllib.request.urlopen('http://localhost:8000/sante').status==200 else 1)"

CMD ["python", "app.py"]
EOF
docker build -t kamer/api:1.0 .
docker images kamer/api
```

> ❓ **Question 4** : Comparez les tailles de `kamer/api:naif` et `kamer/api:1.0`. Citez **trois** améliorations apportées (taille, sécurité, signaux).

### Étape 6 — Cache de construction

```bash
echo "# commentaire" >> app.py
docker build -t kamer/api:1.0 .      # observez « CACHED » sur les premières couches
docker history kamer/api:1.0
```

> ❓ **Question 5** : Quelles couches sont reconstruites après modification de `app.py` ? Pourquoi `COPY app.py` vient-il **après** l'installation des dépendances ou la création de l'utilisateur ?

### Étape 7 — Exécuter, vérifier la santé, observer comme un administrateur

```bash
docker run -d --name api -p 8000:8000 --memory 128m --cpus 0.5 kamer/api:1.0
sleep 12
docker ps                                     # colonne STATUS : (healthy)
curl -s localhost:8000
docker stats --no-stream api
docker top api
docker inspect -f 'PID hôte={{.State.Pid}} OOM={{.State.OOMKilled}}' api
PID=$(docker inspect -f '{{.State.Pid}}' api)
ps -fp "$PID"                                 # c'est un processus de l'hôte !
sudo ls -l /proc/$PID/ns | head -5
cat /sys/fs/cgroup/system.slice/docker-$(docker inspect -f '{{.Id}}' api).scope/memory.max
```

> ❓ **Question 6** : Que prouve la commande `ps -fp "$PID"` à propos de la nature d'un conteneur ? Quelle valeur lit-on dans `memory.max` et d'où vient-elle ?

### Étape 8 — Persistance avec un volume

```bash
curl -s localhost:8000; curl -s localhost:8000      # visites : 2, 3...
docker rm -f api
docker run -d --name api -p 8000:8000 kamer/api:1.0
curl -s localhost:8000                               # le compteur est reparti de 1 !
docker rm -f api

docker volume create donnees-api
docker run -d --name api -p 8000:8000 -v donnees-api:/data kamer/api:1.0
curl -s localhost:8000; curl -s localhost:8000
docker rm -f api
docker run -d --name api -p 8000:8000 -v donnees-api:/data kamer/api:1.0
curl -s localhost:8000                               # le compteur continue
docker volume inspect donnees-api
```

> ❓ **Question 7** : Pourquoi le compteur était-il perdu sans volume ? Où Docker stocke-t-il les données du volume sur l'hôte ?

### Étape 9 — Durcir l'exécution

```bash
docker rm -f api
docker run -d --name api -p 8000:8000 -v donnees-api:/data \
  --read-only --tmpfs /tmp --cap-drop ALL --security-opt no-new-privileges \
  --pids-limit 50 --memory 128m kamer/api:1.0
curl -s localhost:8000
docker exec api id
docker exec api sh -c 'touch /app/test' 2>&1 | tail -1      # refusé : système en lecture seule
```

> ❓ **Question 8** : Quelles protections chaque option apporte-t-elle ? Que se passerait-il si un attaquant exécutait du code dans ce conteneur ?

### Étape 10 — Plusieurs services avec Docker Compose

```bash
cd ~/atelier-docker
docker rm -f api
cat > compose.yaml <<'EOF'
services:
  api:
    build: ./api
    ports:
      - "8000:8000"
    volumes:
      - donnees-api:/data
    restart: unless-stopped
  cache:
    image: redis:7-alpine
    volumes:
      - donnees-redis:/data
volumes:
  donnees-api:
    external: true
  donnees-redis:
EOF
docker compose up -d --build
docker compose ps
docker compose exec cache redis-cli ping
docker compose exec api python -c "import socket; print(socket.gethostbyname('cache'))"
docker compose logs --tail 5 api
docker compose down
```

> ❓ **Question 9** : Comment le service `api` peut-il joindre `cache` par son nom ? Quelle différence entre `docker compose down` et `docker compose down -v` ?

### Étape 11 — Nettoyage

```bash
docker system df
docker rm -f $(docker ps -aq) 2>/dev/null
docker volume rm donnees-api donnees-redis 2>/dev/null
docker image prune -f
```

## ✅ Validation

- [ ] `docker run --rm hello-world` fonctionne sans `sudo`.
- [ ] L'image `kamer/api:1.0` est **plus petite** et utilise un utilisateur non-root (`docker run --rm kamer/api:1.0 id` → `uid=10001`).
- [ ] `docker ps` indique `(healthy)` pour le conteneur.
- [ ] Le compteur de visites **persiste** après suppression et recréation du conteneur grâce au volume.
- [ ] Le conteneur durci refuse l'écriture hors `/data` et `/tmp`.
- [ ] `docker compose up` démarre `api` et `cache`, et `api` résout `cache` par son nom.
- [ ] Vous avez montré qu'un conteneur est un processus de l'hôte avec ses namespaces et son cgroup.

## 💡 Pour aller plus loin

- **Défi 1** : transformez le Dockerfile en **multi-stage** avec une image finale encore plus légère.
- **Défi 2** : scannez l'image avec Trivy : `docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image kamer/api:1.0`.
- **Défi 3** : publiez l'image sur un registre (GitHub Container Registry) avec un tag de version.
- **Défi 4** : limitez la mémoire à 20 Mo et provoquez un `OOMKilled` (`docker inspect -f '{{.State.OOMKilled}}'`).

Atelier suivant : [Pipeline simple](atelier-03-pipeline-simple.md).
