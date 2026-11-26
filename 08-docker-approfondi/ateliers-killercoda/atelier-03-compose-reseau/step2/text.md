# Étape 2 : publier le backend et l'interroger

Pour l'instant, le backend n'est joignable que **depuis le réseau Compose**. Publiez son port 8000 vers l'hôte en réécrivant le fichier avec une clé `ports` :

```bash
cd ~/atelier3
cat > compose.yaml <<'EOF'
name: atelier3

services:
  backend:
    image: python:3.12-alpine
    command: ["python", "-m", "http.server", "8000"]
    ports:
      - "8000:8000"
    networks: [reseau-app]
    depends_on:
      redis:
        condition: service_healthy

  redis:
    image: redis:7-alpine
    networks: [reseau-app]
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 3s
      timeout: 2s
      retries: 10

networks:
  reseau-app:
EOF
```{{exec}}

Appliquez la modification : Compose ne **recrée que** le service dont la configuration a changé.

```bash
docker compose up -d
docker compose ps
```{{exec}}

Testez **depuis l'hôte** :

```bash
curl -s -o /dev/null -w "HTTP %{http_code}\n" localhost:8000
```{{exec}}

Utilisez `docker compose exec` pour agir **dans** les conteneurs en cours d'exécution :

```bash
docker compose exec redis redis-cli ping
docker compose exec redis redis-cli set visite 1
docker compose exec backend wget -qO- http://localhost:8000 | head -n 3
docker compose logs --tail 5 backend
```{{exec}}

Regardez la règle de publication créée par Docker :

```bash
iptables -t nat -S DOCKER | grep 8000
```{{exec}}

> Pourquoi `127.0.0.1:8000:8000` serait-il plus sûr pour un outil d'administration ? Voir le [cours 04](https://github.com/Ghislano26/devops-Worketyamo/blob/main/08-docker-approfondi/cours/04-reseau-et-stockage-docker.md) et le [cours 06](https://github.com/Ghislano26/devops-Worketyamo/blob/main/08-docker-approfondi/cours/06-securite-et-bonnes-pratiques.md).

Cliquez sur **Vérifier** : le port 8000 doit répondre et `exec` doit fonctionner.
