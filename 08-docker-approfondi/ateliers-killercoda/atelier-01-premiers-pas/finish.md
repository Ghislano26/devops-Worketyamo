# Bravo !

Vous avez :

- lancé un conteneur **nginx** et publié un port (`-p 8080:80`) ;
- constaté que la **couche inscriptible** d'un conteneur disparaît avec lui ;
- utilisé un **volume nommé** pour que les données survivent à la recréation des conteneurs.

## Pour aller plus loin

- Essayez un *bind mount* : `docker run --rm -v "$PWD":/work -w /work ubuntu ls`.
- Sauvegardez le volume : `docker run --rm -v donnees:/s:ro -v "$PWD":/b ubuntu tar czf /b/donnees.tgz -C /s .`
- Lisez le [cours Images et couches](https://github.com/Ghislano26/devops-Worketyamo/blob/main/08-docker-approfondi/cours/02-images-et-couches.md), puis passez à l'[atelier 2 : Dockerfile multi-stage](https://github.com/Ghislano26/devops-Worketyamo/tree/main/08-docker-approfondi/ateliers-killercoda/atelier-02-dockerfile-multistage).
