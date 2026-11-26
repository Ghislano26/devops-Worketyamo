# Étape 1 : le Dockerfile « qui marche »

Créez l'application (une petite API Flask) :

```bash
mkdir -p ~/api && cd ~/api
cat > app.py <<'EOF'
from flask import Flask, jsonify

app = Flask(__name__)


@app.get("/")
def index():
    return jsonify(service="api", statut="ok")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF
echo "flask==3.0.3" > requirements.txt
```{{exec}}

Écrivez maintenant un Dockerfile **naïf** : image complète, tout copié, exécution en root.

```bash
cat > Dockerfile <<'EOF'
FROM python:3.12
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
EXPOSE 5000
CMD python app.py
EOF
```{{exec}}

Construisez l'image `api:naive` et **notez sa taille** :

```bash
docker build -t api:naive .
```{{exec}}

```bash
docker image ls api
docker history api:naive | head -n 8
```{{exec}}

> Combien de Mo ? Environ 1 Go pour une API de dix lignes ! La base `python:3.12` embarque compilateur, en-têtes et outils inutiles à l'exécution. De plus, `CMD python app.py` est en forme *shell* et `COPY . .` précède les dépendances : le cache sera invalidé à chaque modification du code ([cours 03](https://github.com/Ghislano26/devops-Worketyamo/blob/main/08-docker-approfondi/cours/03-dockerfile-avance.md)).

Cliquez sur **Vérifier** quand l'image `api:naive` existe.
