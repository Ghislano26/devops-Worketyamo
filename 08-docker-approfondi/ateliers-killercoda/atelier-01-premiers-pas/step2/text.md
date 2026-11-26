# Étape 2 : les données d'un conteneur sont éphémères

## A. La couche inscriptible disparaît avec le conteneur

Ouvrez un shell **interactif** dans un conteneur `ubuntu` nommé `bac` :

```bash
docker run -it --name bac ubuntu bash
```{{exec}}

Dans ce conteneur, créez un fichier, lisez-le, puis quittez :

```bash
echo "bonjour" > /note.txt && cat /note.txt
exit
```{{exec}}

Le conteneur est arrêté mais **existe encore** : son fichier aussi. Voyez-le avec `docker diff`, puis supprimez le conteneur :

```bash
docker diff bac
docker rm bac
```{{exec}}

Recréez un conteneur à partir de la **même image** : le fichier a disparu.

```bash
docker run --rm ubuntu cat /note.txt
```{{exec}}

(Erreur « No such file or directory » : normal !) Pourquoi ? Une image est **immuable** ; chaque conteneur a sa propre couche inscriptible, détruite avec lui ([cours 01](https://github.com/Ghislano26/devops-Worketyamo/blob/main/08-docker-approfondi/cours/01-architecture-docker.md)).

## B. Un volume nommé survit aux conteneurs

Créez un volume **`donnees`** et écrivez-y un fichier depuis un premier conteneur :

```bash
docker volume create donnees
docker run --rm -v donnees:/data ubuntu bash -c 'echo "je persiste" > /data/note.txt'
```{{exec}}

Ce conteneur n'existe plus (`--rm`). **Recréez-en un autre** qui monte le même volume :

```bash
docker run --rm -v donnees:/data ubuntu cat /data/note.txt
```{{exec}}

Le texte « je persiste » doit s'afficher. Regardez où Docker stocke le volume sur l'hôte :

```bash
docker volume inspect donnees
ls /var/lib/docker/volumes/donnees/_data
```{{exec}}

Cliquez sur **Vérifier** quand le fichier persiste après recréation d'un conteneur.
