# Votre premier workflow GitHub Actions

**Durée : ~25 minutes.** Compétence travaillée : écrire un **workflow YAML** et l'exécuter **localement** avec **`act`**.

> **Pourquoi `act` ?** Killercoda ne peut pas déclencher de vrais workflows GitHub (il n'est pas relié à votre dépôt). `act` exécute les mêmes fichiers `.github/workflows/*.yml` dans des conteneurs Docker, ce qui permet d'itérer vite avant de pousser. Il imite GitHub sans être identique (voir les limites dans le [cours 2](https://github.com/Ghislano26/devops-Worketyamo/blob/main/12-cicd/cours/02-pipeline-as-code-github-actions.md)).

Rappel :

```text
on (déclencheur) → jobs (parallèles) → steps (séquentielles) → run / uses
```

## Mise en place

Ce script installe `act`, déclare une image légère pour `ubuntu-latest` et crée un dépôt de travail :

```bash
curl -fsSL https://raw.githubusercontent.com/nektos/act/master/install.sh | bash -s -- -b /usr/local/bin
act --version
echo '-P ubuntu-latest=node:20-bookworm-slim' > ~/.actrc
mkdir -p ~/ci-actions/.github/workflows && cd ~/ci-actions && git init -q
docker pull node:20-bookworm-slim
ls -a ~/ci-actions
```{{exec}}

> L'image `node:20-bookworm-slim` est bien plus légère que les images « complètes » des runners GitHub : elle suffit pour des étapes `run:` simples. Si une action tierce échoue faute d'un outil, utilisez `catthehacker/ubuntu:act-22.04` à la place dans `~/.actrc`.
