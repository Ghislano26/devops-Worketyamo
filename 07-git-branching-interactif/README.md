# Module 07 — Git branching interactif

## Pourquoi ce module ?

Le [module 05](../05-devops-outils/cours/01-git-workflow.md) vous a appris à utiliser Git. Ce module vous apprend à
**le comprendre**. Git n'est pas une suite de fichiers modifiés : c'est un **graphe de commits** sur lequel on déplace des
**pointeurs**. Une fois ce modèle en tête, `merge`, `rebase`, `cherry-pick` et `reflog` cessent d'être des incantations : on peut
**dessiner** le résultat avant de lancer la commande.

Pour cela, le module combine des cours illustrés (diagrammes Mermaid), des ateliers sur de vrais dépôts et des
**[exercices interactifs animés](interactif/index.html)** où l'on voit le graphe évoluer à chaque commande.

> Ce module est **indépendant** des cours Linux (01 à 04) : seule la maîtrise de la console (module 01) et les bases de Git (module 05) sont supposées.

## Prérequis

- Savoir utiliser la console ([module 01](../01-linux-fondamentaux/cours/03-navigation-commandes-base.md)).
- Git installé et configuré : `git --version`, `git config --global user.name`, `user.email` (voir la [checklist du module 00](../00-installation-ubuntu-vm/checklist-post-installation.md)).
- Avoir fait l'[atelier Git du module 05](../05-devops-outils/ateliers/atelier-01-git-branches.md) (commits, branches, première fusion) est un plus.
- Un **navigateur web** pour la partie interactive (aucun serveur ni outil à installer).
- Les diagrammes **Mermaid** s'affichent sur GitHub/GitLab ; ailleurs, utilisez un éditeur Markdown compatible.

## Parcours recommandé

| # | Cours | Atelier / exercice associé |
|---|---|---|
| 1 | [Modéliser Git](cours/01-modeliser-git.md) — DAG, commits, HEAD, refs, trois espaces | [Atelier 01 — Premiers commits et branches](ateliers/atelier-01-premiers-commits-branches.md) · [Exercice 1](interactif/exercices/01-branches-de-base.html) |
| 2 | [Branches et checkout](cours/02-branches-et-checkout.md) — pointeurs, `switch`, distants, HEAD détaché | *(même atelier)* |
| 3 | [Merge, rebase, cherry-pick](cours/03-merge-rebase-cherry-pick.md) — fast-forward, réécriture, conflits | [Atelier 02 — Merge vs rebase](ateliers/atelier-02-merge-vs-rebase.md) · [Atelier 03 — Cherry-pick et tags](ateliers/atelier-03-cherry-pick-et-tags.md) · exercices [2](interactif/exercices/02-merge.html), [3](interactif/exercices/03-rebase.html), [4](interactif/exercices/04-cherry-pick.html) |
| 4 | [Reflog et récupération](cours/04-reflog-et-recuperation.md) — `reset`, `revert`, retrouver un commit perdu | [Atelier 04 — Récupération avec reflog](ateliers/atelier-04-recuperation-reflog.md) |
| 5 | [Workflows d'équipe](cours/05-workflows-equipe.md) — GitHub Flow, Git Flow, trunk-based, PR, Conventional Commits | *(mise en pratique : [atelier CI/CD du module 05](../05-devops-outils/ateliers/atelier-03-pipeline-simple.md))* |

Conseil de méthode : **faites l'exercice interactif avant l'atelier correspondant**. Voir le graphe bouger rend le modèle évident, et l'atelier le confirme sur un vrai dépôt.

## La partie interactive

| Page | Contenu |
|---|---|
| [`interactif/index.html`](interactif/index.html) | Sommaire des exercices (à ouvrir **dans un navigateur**) |
| [`interactif/README.md`](interactif/README.md) | Mode d'emploi, commandes, animations, création d'un exercice |
| Exercices | [Branches](interactif/exercices/01-branches-de-base.html) · [Merge](interactif/exercices/02-merge.html) · [Rebase](interactif/exercices/03-rebase.html) · [Cherry-pick](interactif/exercices/04-cherry-pick.html) |
| Mode démo | Ajoutez `?autoplay=1` à l'adresse d'un exercice pour voir la solution se rejouer en boucle |

Pas de serveur, pas de `npm` : ouvrez simplement les fichiers `.html`.

## Ce que vous saurez faire à la fin

- Représenter n'importe quel dépôt comme un **graphe** et prédire l'effet d'une commande.
- Choisir entre **merge** et **rebase**, et appliquer la **règle d'or** du rebase.
- **Récupérer** du travail « perdu » avec le reflog, et annuler un commit publié avec `revert`.
- Rétroporter un correctif avec `cherry-pick` et publier des **versions** avec des tags annotés.
- Choisir et mettre en œuvre un **workflow d'équipe** (protection de branches, PR, Conventional Commits).

> ⚠️ **Attention** : les ateliers réécrivent volontairement l'historique (`rebase`, `reset --hard`). Ils travaillent dans des dépôts jetables sous `~/git-lab` : ne les exécutez jamais dans un dépôt contenant du vrai travail.

## Navigation

- [← Module 06 — Réseaux pour DevOps](../06-reseaux-devops/README.md)
- [← Retour au README principal](../README.md)
