# Exercices Git interactifs

Une mini-application web **statique et autonome** : on tape des commandes Git fictives et le **graphe des commits se
met à jour avec animation**. Inspirée de [Learn Git Branching](https://learngitbranching.js.org/), mais volontairement
plus simple : HTML, CSS et JavaScript « à l'ancienne », **sans npm, sans build, sans framework, sans dépendance externe**.

## Ouvrir les exercices

Aucun serveur n'est nécessaire :

1. Téléchargez ou clonez le dépôt.
2. Ouvrez [`index.html`](index.html) **directement dans un navigateur** (double-clic, ou *Fichier → Ouvrir*).
3. Choisissez un exercice. Chaque page est aussi ouvrable seule (`exercices/01-branches-de-base.html`, etc.).

Depuis un terminal :

```bash
xdg-open 07-git-branching-interactif/interactif/index.html     # Linux
open     07-git-branching-interactif/interactif/index.html     # macOS
```

*(Si votre navigateur restreint les fichiers locaux, `python3 -m http.server 8000` dans ce dossier fonctionne aussi, mais ce n'est jamais obligatoire.)*

> 💡 **Conseil** : sur la VM Ubuntu **Server** (sans interface graphique), ouvrez plutôt ces pages depuis votre ordinateur hôte.

## Les exercices

| Page | Notion | Cours associé |
|---|---|---|
| [`01-branches-de-base.html`](exercices/01-branches-de-base.html) | Créer une branche, `switch`, diverger | [Branches et checkout](../cours/02-branches-et-checkout.md) |
| [`02-merge.html`](exercices/02-merge.html) | Fusion à trois points, fast-forward | [Merge, rebase, cherry-pick](../cours/03-merge-rebase-cherry-pick.md) |
| [`03-rebase.html`](exercices/03-rebase.html) | Rejouer des commits, historique linéaire | idem |
| [`04-cherry-pick.html`](exercices/04-cherry-pick.html) | Copier des commits précis | idem |

## Utilisation

- Tapez une commande dans la console du bas, puis **Entrée**. `↑` / `↓` parcourent l'historique des commandes.
- L'objectif est affiché en haut ; un **test de réussite** s'exécute après **chaque** commande. Quand il est validé, une coche verte animée apparaît.
- **💡 Indice** (progressif), **🧩 Solution**, **↺ Réinitialiser** (ou tapez `reset`), **▶ Démo animée**.

### Commandes prises en charge

| Commande | Effet |
|---|---|
| `git commit -m "message"` | Crée un commit sur la branche courante |
| `git branch <nom>` | Crée une branche (sans y aller) ; `git branch` seule les liste ; `-d` / `-D` suppriment |
| `git switch <nom>` / `git checkout <nom>` | Change de branche (`-c` / `-b` pour créer ; `git switch --detach <réf>` ou `git checkout <commit>` détachent HEAD) |
| `git merge <nom>` | Fast-forward ou commit de fusion à deux parents |
| `git rebase <nom>` | Rejoue les commits de la branche courante sur `<nom>` (nouveaux commits `C4'`) |
| `git cherry-pick <commit>...` | Copie un ou plusieurs commits (`C4'`) |
| `git reset --hard <réf>` | Déplace la branche courante vers `<réf>` (les commits laissés derrière deviennent orphelins) |
| `git log`, `git status` | Informations |
| `reset`, `help`, `hint`, `solution`, `clear` | Commandes de l'application |

Les références acceptées : nom de branche, identifiant de commit (`C3`, insensible à la casse), `HEAD`, `HEAD~2`, `main^`.
Une commande invalide affiche un **message d'erreur explicite** dans la console (préfixé `✘`).

## Mode démo (`?autoplay=1`)

Ajoutez `?autoplay=1` à l'adresse d'un exercice (ou cliquez sur **▶ Démo animée**) :

```text
exercices/03-rebase.html?autoplay=1
```

Les commandes de la solution sont **tapées puis exécutées automatiquement**, avec le graphe animé, puis la démo **recommence en boucle**.
Appuyez sur une touche ou cliquez sur **Arrêter la démo** pour reprendre la main.

## Les animations

| Évènement | Animation |
|---|---|
| Nouveau commit | Le cercle apparaît (fondu + zoom, `@keyframes pop`) |
| Nouveau lien de parenté | La flèche se **dessine** (`stroke-dashoffset`, `@keyframes drawLine`) |
| Branche ou HEAD qui bouge | L'étiquette **glisse** vers le nouveau commit (`transition` CSS sur `transform`) |
| Commit devenu orphelin | Passage en pointillés et atténuation (`transition: all 0.3s ease`) |
| Objectif atteint | Cercle et coche verte dessinés, puis zoom du message (`@keyframes fadeIn`, `pop`, `drawLine`) |

Si votre système demande de **réduire les animations** (`prefers-reduced-motion`), elles sont automatiquement désactivées.

## Organisation des fichiers

```text
interactif/
├── index.html            # sommaire (affiche une coche sur les exercices réussis)
├── css/style.css         # styles, thème clair/sombre, @keyframes
├── js/git-graph.js       # moteur Git fictif + rendu SVG + console (aucune dépendance)
└── exercices/
    ├── 01-branches-de-base.html
    ├── 02-merge.html
    ├── 03-rebase.html
    └── 04-cherry-pick.html
```

`js/git-graph.js` contient trois couches : le **modèle** (`Repo` : commits, branches, HEAD, commandes), la **mise en page**
(`layout`, une « voie » par branche) et le **rendu SVG** (`Renderer`) ; l'interface (`GitGraph.exercise`) assemble le tout.
Le code est commenté en français.

## Créer un nouvel exercice

Copiez une page de `exercices/` et modifiez la configuration passée à `GitGraph.exercise` :

```js
GitGraph.exercise({
  mount: '#app',
  id: '05-mon-exercice',                       // sert à mémoriser la réussite
  initial: {                                   // état de départ
    commits: [{ id: 'C1', parents: [], msg: 'Initialise' }, { id: 'C2', parents: ['C1'], msg: 'Suite' }],
    branches: { main: 'C2' },
    head: 'main'
  },
  goal: { html: '<p>Énoncé de l\'objectif…</p>' },
  check: function (repo) {                     // appelé après chaque commande : renvoie true si réussi
    return repo.tip('main') === 'C2';
  },
  hints: ['Premier indice…'],
  solution: ['git commit -m "x"'],
  demo: ['git commit -m "x"'],                 // rejoué par ?autoplay=1
  next: { href: '../index.html', label: 'Retour au sommaire →' }
});
```

Aides utiles pour écrire `check` : `repo.tip('branche')`, `repo.parentOf(id)`, `repo.ancestors(id)`, `repo.commits[id]`, `repo.head`.
Pensez à placer les commits de la branche principale **en premier** dans `commits` : l'ordre détermine la disposition du graphe.

## Limites volontaires

Cette application illustre le **modèle** (graphe, pointeurs). Elle ne gère ni fichiers, ni conflits, ni dépôts distants, ni `rebase -i`. Pour cela,
utilisez de vrais dépôts dans les [ateliers](../ateliers/atelier-02-merge-vs-rebase.md).

## Accessibilité

Contrastes de couleurs élevés, contour de **focus** visible, console annoncée aux lecteurs d'écran (`role="log"`), champ de commande étiqueté,
information jamais portée par la seule couleur (icônes ✔ / ✘ et texte), animations réductibles.
