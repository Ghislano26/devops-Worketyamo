# Étape 2 : multi-stage, non-root, image `slim`

Principe : une étape **`build`** installe les dépendances dans un environnement virtuel ; l'étape **finale**, basée sur `python:3.12-slim`, ne copie que cet environnement et le code, puis s'exécute avec un utilisateur **non-root**.

```bash
cd ~/api
cat > Dockerfile.multistage <<'EOF'
# syntax=docker/dockerfile:1

# ---------- Étape 1 : construction ----------
FROM python:3.12-slim AS build
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ---------- Étape 2 : exécution ----------
FROM python:3.12-slim
ENV PATH="/opt/venv/bin:$PATH" PYTHONUNBUFFERED=1
COPY --from=build /opt/venv /opt/venv
WORKDIR /app
COPY app.py .
RUN useradd --system --uid 10001 --no-create-home appuser
USER 10001
EXPOSE 5000
CMD ["python", "app.py"]
EOF
```{{exec}}

Construisez l'image `api:optimise` et **comparez** les tailles :

```bash
docker build -f Dockerfile.multistage -t api:optimise .
docker image ls api
```{{exec}}

Lancez-la sous le nom **`api`**, en publiant le port 5000, et testez :

```bash
docker run -d --name api -p 5000:5000 api:optimise
sleep 2
curl -s localhost:5000
docker exec api id
```{{exec}}

La réponse JSON doit s'afficher, et `id` doit montrer l'UID **10001** (pas root).

## Questions de compréhension

- Pourquoi l'image est-elle plus petite ? (Base `slim` ; pas de cache `pip` ; seul l'environnement virtuel est copié.)
- Que se passe-t-il au deuxième `docker build` si vous modifiez seulement `app.py` ? Essayez : `echo "# test" >> app.py` puis relancez le build et repérez les étapes `CACHED`.
- `docker stop api` est-il rapide ? Pourquoi la forme *exec* de `CMD` aide-t-elle ?

Cliquez sur **Vérifier** : l'image optimisée doit être plus petite que la naïve, et le conteneur `api` doit répondre.
