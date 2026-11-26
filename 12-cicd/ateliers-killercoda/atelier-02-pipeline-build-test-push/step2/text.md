# Étape 2 : le Dockerfile et `make build`

Écrivez le `Dockerfile` : image légère, **utilisateur non root**, seul le fichier utile est copié ([cours 4](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/04-build-artefacts-et-registries.md)).

```bash
cd ~/cicd-app
cat > Dockerfile <<'EOF'
FROM python:3.12-slim
WORKDIR /app
COPY app.py .
USER 10001
EXPOSE 8080
CMD ["python", "app.py"]
EOF
cat Dockerfile
```{{exec}}

Lancez la cible **`build`** : elle exécute les tests **puis** construit l'image avec deux tags (la version et `latest`) :

```bash
make build
docker images localhost:5000/monapp
```{{exec}}

Testez l'image :

```bash
docker run -d --name monapp-test -p 8080:8080 localhost:5000/monapp:1.0.0
sleep 2; curl -s http://localhost:8080; echo
docker rm -f monapp-test
```{{exec}}

## Questions

- Pourquoi une version **exacte** (`1.0.0`) en plus de `latest` ? (Le tag exact est la référence de déploiement ; `latest` est mutable.)
- Que se passerait-il si un test échouait ? (`make build` s'arrêterait : aucune image construite.)

Cliquez sur **Vérifier**.
