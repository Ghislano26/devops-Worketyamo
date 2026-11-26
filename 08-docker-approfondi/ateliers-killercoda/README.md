# Ateliers Killercoda — Docker approfondi

Ces trois scénarios s'exécutent sur **[Killercoda](https://killercoda.com/)** : une plateforme gratuite qui ouvre, dans le navigateur, un
terminal sur une vraie machine Linux préconfigurée. Rien à installer, rien à casser sur votre ordinateur.

| Scénario | Durée | Notions | Cours associés |
|---|---|---|---|
| [`atelier-01-premiers-pas`](atelier-01-premiers-pas/) | ~15 min | `docker run`, publication de port, conteneur éphémère, volume nommé | [01](../cours/01-architecture-docker.md), [04](../cours/04-reseau-et-stockage-docker.md) |
| [`atelier-02-dockerfile-multistage`](atelier-02-dockerfile-multistage/) | ~20 min | Dockerfile naïf, multi-stage, non-root, comparaison des tailles | [02](../cours/02-images-et-couches.md), [03](../cours/03-dockerfile-avance.md) |
| [`atelier-03-compose-reseau`](atelier-03-compose-reseau/) | ~20 min | Compose, réseau personnalisé, DNS interne, `healthcheck`, publication de port | [04](../cours/04-reseau-et-stockage-docker.md), [05](../cours/05-docker-compose.md) |

**Lisez le cours associé avant chaque atelier** : l'atelier vérifie vos acquis, il ne réexplique pas la théorie.

## Environnement

Les trois scénarios utilisent le backend **`ubuntu`** (`"backend": {"imageid": "ubuntu"}` dans `index.json`) : une machine Ubuntu avec **Docker préinstallé**.
Les scripts `verify.sh` sont exécutés dans ce même terminal. Les scénarios supposent un accès à Internet (téléchargement des images `nginx`, `python`, `redis`).

## Structure d'un scénario

Chaque dossier suit le format imposé par Killercoda :

```text
atelier-0X-nom/
├── index.json          # métadonnées : titre, étapes, image de l'environnement
├── intro.md            # page d'accueil du scénario
├── step1/
│   ├── text.md         # énoncé de l'étape (Markdown)
│   └── verify.sh       # script de vérification (code retour 0 = étape réussie)
├── step2/
│   ├── text.md
│   └── verify.sh
└── finish.md           # page de fin
```

Éléments de syntaxe Killercoda utilisés dans les `text.md` :

| Syntaxe | Effet |
|---|---|
| ` ```bash … ```{{exec}} ` | Un clic **exécute** le bloc dans le terminal |
| ` ```bash … ```{{copy}} ` | Un clic **copie** le bloc |

Le bouton **Vérifier** exécute `verify.sh` : un **code de retour 0** passe à l'étape suivante, un code différent de 0 affiche le message (écrit sur la sortie) et reste sur l'étape.

## Publier ces scénarios sur Killercoda

1. Créez-vous un compte sur <https://killercoda.com/> (connexion GitHub possible), puis ouvrez votre profil → **Creator**.
2. **Liez ce dépôt GitHub** à votre profil Killercoda (le dépôt doit être public, ou l'accès accordé via la GitHub App de Killercoda). Killercoda lit les scénarios dans le dépôt et se met à jour à chaque *push*.
3. Pour chaque scénario, l'image de l'environnement est définie dans `index.json` : **`ubuntu`** pour Docker (`kubernetes-kubeadm-1node` pour le [module 09](../../09-kubernetes-approfondi/ateliers-killercoda/README.md)).
4. Lancez le scénario depuis votre page Creator ; vous pouvez aussi **prévisualiser** vos modifications avant de les publier.

> ⚠️ **Attention** : Killercoda détecte les scénarios selon la **structure du dépôt** (dossiers contenant un `index.json`, éventuellement déclarés par un fichier `structure.json`). Ces scénarios sont ici rangés sous
> `08-docker-approfondi/ateliers-killercoda/`. Si Killercoda ne les trouve pas à cet emplacement, consultez la documentation « Creators » de la plateforme
> (<https://killercoda.com/creators>) : il faudra peut-être déclarer ces chemins dans un `structure.json` ou déplacer les dossiers `atelier-0X-*` à la racine d'un dépôt dédié aux scénarios.

## Tester un scénario en local (sans Killercoda)

Les commandes sont des commandes Docker standard : vous pouvez les suivre sur la VM Ubuntu du [module 00](../../00-installation-ubuntu-vm/README.md) (Docker installé : [module 05](../../05-devops-outils/cours/02-docker-fondamentaux.md)).
Les scripts de vérification se lancent à la main :

```bash
bash atelier-01-premiers-pas/step1/verify.sh ; echo "code retour = $?"
```

## Rappel du module

[← Retour au module 08](../README.md)
