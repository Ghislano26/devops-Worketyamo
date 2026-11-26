# Ateliers Killercoda — Linux expert (module 04)

Des ateliers **courts (5 à 10 minutes)**, focalisés sur **une compétence**, qui s'exécutent dans le navigateur sur **[Killercoda](https://killercoda.com/)** : un serveur Ubuntu réel, sans installer de VM. Chaque étape est validée par un script `verify.sh` **strict**.

| Scénario | Compétence | Cours associé | Version « sur mon serveur » |
|---|---|---|---|
| [`atelier-01-namespaces-cgroups-killercoda`](atelier-01-namespaces-cgroups-killercoda/) | Namespaces et cgroups | [02 — Conteneurs : namespaces et cgroups](../cours/02-conteneurs-namespaces.md) | [Atelier](../ateliers/atelier-02-namespaces-cgroups.md) |

> 💡 **Conseil** : les ateliers Killercoda sont un **échauffement** ou une **révision**. Le vrai apprentissage a lieu sur **ton** serveur (voir le [parcours](../PARCOURS.md)). Lis d'abord le cours associé : l'atelier vérifie, il n'explique pas.

## Environnement

Backend **`ubuntu`** (`"backend": {"imageid": "ubuntu"}` dans chaque `index.json`) : une machine Ubuntu où tu es **root** (les `sudo` des cours ne sont pas nécessaires ici, mais ils fonctionnent). L'environnement est jetable.

## Structure d'un scénario

```text
atelier-XX-nom-killercoda/
├── index.json        # titre, description, étapes, image de l'environnement
├── intro.md          # introduction
├── step1/{text.md, verify.sh}
├── step2/{text.md, verify.sh}
└── finish.md         # résumé et suite
```

Dans les `text.md`, un bloc ` ```bash … ```{{exec}} ` s'exécute d'un clic. Le bouton **Vérifier** lance `verify.sh` : code de retour **0** = étape réussie ; sinon le message affiché te dit ce qu'il manque.

## Lancer ces scénarios

1. Crée un compte sur <https://killercoda.com/> (connexion GitHub possible) → profil → **Creator**.
2. **Lie ce dépôt GitHub** à ton profil Killercoda ; les scénarios sont lus dans le dépôt et mis à jour à chaque *push*.
3. Lance le scénario depuis ta page Creator (avec prévisualisation).

> ⚠️ **Attention** : Killercoda détecte les scénarios selon la **structure du dépôt** (dossiers contenant un `index.json`, éventuellement déclarés par un `structure.json`). Ces scénarios sont ici sous `04-linux-expert/ateliers-killercoda/`. Si la plateforme ne les trouve pas à cet emplacement, consulte la documentation « Creators » (<https://killercoda.com/creators>).

## Sans Killercoda

Les commandes sont standard : tu peux les suivre sur ta VM Ubuntu (préfixe `sudo` si tu n'es pas root) et lancer les vérifications à la main :

```bash
sudo bash atelier-01-xxx-killercoda/step1/verify.sh ; echo "code retour = $?"
```

[← Retour au README du module](../README.md) · [Parcours](../PARCOURS.md)
