# Étape 1 : backend + redis sur `reseau-app`

Créez le dossier de travail et le fichier Compose :

```bash
mkdir -p ~/atelier3 && cd ~/atelier3
cat > compose.yaml <<'EOF'
name: atelier3

services:
  backend:
    image: python:3.12-alpine
    command: ["python", "-m", "http.server", "8000"]
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

Validez puis démarrez la pile :

```bash
docker compose config -q && echo "fichier valide"
docker compose up -d
docker compose ps
```{{exec}}

Le `backend` ne démarre qu'**après** que `redis` est **healthy** (`depends_on` + `condition: service_healthy`, voir le [cours 05](https://github.com/Ghislano26/devops-Worketyamo/blob/main/08-docker-approfondi/cours/05-docker-compose.md)).

## Le DNS interne

Sur un réseau **personnalisé**, Docker fournit un DNS embarqué : les services se joignent **par leur nom**.

```bash
docker compose exec backend ping -c 2 redis
docker compose exec backend cat /etc/resolv.conf
docker compose exec backend nslookup redis
```{{exec}}

Notez : le résolveur est `127.0.0.11`, et `redis` est résolu en une adresse du sous-réseau du réseau. Regardez le réseau créé :

```bash
docker network ls | grep atelier3
docker network inspect atelier3_reseau-app -f '{{range .Containers}}{{.Name}} {{.IPv4Address}}{{"\n"}}{{end}}'
```{{exec}}

> Pourquoi le réseau s'appelle-t-il `atelier3_reseau-app` ? Compose préfixe les ressources par le **nom du projet** (`name: atelier3`).

Cliquez sur **Vérifier** quand les deux services tournent sur le réseau.
