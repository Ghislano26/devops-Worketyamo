# Dockerfile multi-stage

Un Dockerfile qui « marche » n'est pas forcément un bon Dockerfile. Dans cet atelier, vous allez :

1. construire une image **naïve** pour une petite API Python et **mesurer** sa taille ;
2. la **réécrire en multi-stage** (build / runtime), avec un utilisateur **non-root**, et comparer.

Rappel du [cours Dockerfile avancé](https://github.com/Ghislano26/devops-Worketyamo/blob/main/08-docker-approfondi/cours/03-dockerfile-avance.md) :

- un build **multi-stage** utilise plusieurs `FROM` ; seule la **dernière** étape devient l'image finale ;
- on y copie **uniquement les artefacts** (`COPY --from=build`) : compilateur, caches et sources de build disparaissent ;
- on place les **dépendances avant le code** pour profiter du cache, et on termine par `USER` non-root.

Vérifions l'environnement :

```bash
docker --version && docker buildx version
```{{exec}}

Le téléchargement des images `python` peut prendre une minute : c'est normal.
