# Cheatsheet — Vim

Vim est présent sur pratiquement tous les serveurs. Savoir **ouvrir, modifier, enregistrer et quitter** est une
compétence de survie. Pour s'entraîner : `vimtutor` (tutoriel interactif de 30 minutes, installé avec `vim`).

## Les modes : la clé de Vim

```text
              i, a, o, I, A, O                    v, V, Ctrl+v
 ┌──────────┐ ─────────────► ┌───────────┐     ┌──────────────┐
 │  NORMAL  │                │ INSERTION │     │    VISUEL    │
 │ (défaut) │ ◄───────────── │ (écrire)  │     │ (sélection)  │
 └──────────┘      Échap     └───────────┘     └──────────────┘
      │  :
      ▼
 ┌──────────┐
 │ COMMANDE │   :w  :q  :wq  :%s/a/b/g
 └──────────┘
```

| Mode | Rôle | Entrer | Sortir |
|---|---|---|---|
| **Normal** | Se déplacer, copier, supprimer | `Échap` (depuis n'importe où) | — |
| **Insertion** | Taper du texte | `i` `a` `o` … | `Échap` |
| **Visuel** | Sélectionner | `v` `V` `Ctrl+v` | `Échap` |
| **Commande** | Commandes `:` | `:` | `Entrée` / `Échap` |

> 📌 **À retenir** : en cas de doute, **appuyez sur `Échap` deux fois** : vous êtes en mode normal.

## Survie : ouvrir, enregistrer, quitter

| Commande | Effet |
|---|---|
| `vim fichier` | Ouvrir (ou créer) |
| `vim +42 fichier` | Ouvrir à la ligne 42 |
| `:w` | Enregistrer |
| `:q` | Quitter |
| `:wq` ou `:x` ou `ZZ` | Enregistrer et quitter |
| `:q!` ou `ZQ` | Quitter **sans** enregistrer |
| `:w nouveau.txt` | Enregistrer sous |
| `:w !sudo tee %` | Enregistrer un fichier root ouvert sans sudo |
| `:e fichier` | Ouvrir un autre fichier |
| `:r fichier` | Insérer le contenu d'un fichier |
| `:!commande` | Exécuter une commande shell |

## Se déplacer (mode normal)

| Touches | Déplacement |
|---|---|
| `h` `j` `k` `l` | ← ↓ ↑ → |
| `w` / `b` / `e` | Mot suivant / précédent / fin de mot |
| `0` / `^` / `$` | Début de ligne / premier caractère / fin de ligne |
| `gg` / `G` | Début / fin du fichier |
| `42G` ou `:42` | Aller à la ligne 42 |
| `Ctrl+f` / `Ctrl+b` | Page suivante / précédente |
| `Ctrl+d` / `Ctrl+u` | Demi-page bas / haut |
| `%` | Parenthèse/accolade correspondante |
| `{` / `}` | Paragraphe précédent / suivant |
| `H` `M` `L` | Haut / milieu / bas de l'écran |
| `Ctrl+o` / `Ctrl+i` | Position précédente / suivante |

Un **nombre** devant répète : `5j` descend de 5 lignes, `3w` avance de 3 mots.

## Passer en insertion

| Touche | Effet |
|---|---|
| `i` / `a` | Avant / après le curseur |
| `I` / `A` | Début / fin de ligne |
| `o` / `O` | Nouvelle ligne dessous / dessus |
| `cw` | Remplace le mot |
| `cc` / `C` | Remplace la ligne / jusqu'à la fin |
| `r` / `R` | Remplace un caractère / mode remplacement |

## Éditer : la grammaire *verbe + objet*

Une commande se compose d'un **opérateur** et d'un **mouvement** : `d` + `w` = supprimer un mot.

| Opérateur | Effet |
|---|---|
| `d` | Supprimer (couper) |
| `y` | Copier (*yank*) |
| `c` | Changer (supprime puis passe en insertion) |
| `>` / `<` | Indenter / désindenter |
| `gU` / `gu` | Majuscules / minuscules |

| Exemple | Effet |
|---|---|
| `dd` | Supprime la ligne |
| `dw` | Supprime un mot |
| `d$` ou `D` | Supprime jusqu'à la fin de la ligne |
| `d3d` ou `3dd` | Supprime 3 lignes |
| `dgg` / `dG` | Supprime jusqu'au début / à la fin du fichier |
| `yy` / `y$` | Copie la ligne / jusqu'à la fin |
| `p` / `P` | Colle après / avant |
| `ciw` | Change le mot sous le curseur |
| `ci"` | Change le contenu entre guillemets |
| `di(` | Supprime le contenu entre parenthèses |
| `x` / `X` | Supprime le caractère courant / précédent |
| `J` | Joint la ligne suivante |
| `.` | **Répète** la dernière modification |
| `u` / `Ctrl+r` | Annuler / rétablir |
| `~` | Inverse la casse du caractère |

> 💡 **Conseil** : `.` (point) est l'une des commandes les plus puissantes : faites une modification, déplacez-vous, tapez `.` pour la répéter.

## Sélection (mode visuel)

| Touche | Effet |
|---|---|
| `v` | Sélection par caractères |
| `V` | Sélection par lignes |
| `Ctrl+v` | Sélection en bloc (colonne) |
| puis `d` `y` `c` `>` `<` `U` `u` | Opérateur sur la sélection |

Insérer un texte sur plusieurs lignes : `Ctrl+v`, sélectionner les lignes, `I`, taper le texte, `Échap`.

## Recherche et remplacement

| Commande | Effet |
|---|---|
| `/motif` | Cherche vers l'avant |
| `?motif` | Cherche vers l'arrière |
| `n` / `N` | Occurrence suivante / précédente |
| `*` / `#` | Cherche le mot sous le curseur (avant / arrière) |
| `:noh` | Efface la surbrillance |
| `:s/a/b/` | Remplace (1re occurrence de la ligne) |
| `:s/a/b/g` | Remplace toutes les occurrences de la ligne |
| `:%s/a/b/g` | Remplace dans tout le fichier |
| `:%s/a/b/gc` | Idem, avec **confirmation** |
| `:5,10s/a/b/g` | Sur les lignes 5 à 10 |
| `:g/motif/d` | Supprime toutes les lignes contenant le motif |
| `:v/motif/d` | Supprime toutes les lignes **ne** contenant **pas** le motif |
| `:%s/\s\+$//e` | Supprime les espaces en fin de ligne |

Options de recherche : `:set ignorecase smartcase incsearch hlsearch`.

## Fenêtres, onglets, tampons

| Commande | Effet |
|---|---|
| `:split f` / `:vsplit f` | Divise horizontalement / verticalement |
| `Ctrl+w` puis `h/j/k/l` | Change de fenêtre |
| `Ctrl+w` puis `q` | Ferme la fenêtre |
| `:tabnew f` / `gt` / `gT` | Onglet : nouveau / suivant / précédent |
| `:ls` / `:b2` | Liste des tampons / aller au tampon 2 |

## Registres, marques, macros

| Commande | Effet |
|---|---|
| `"ayy` puis `"ap` | Copie dans le registre `a`, colle depuis `a` |
| `"+y` / `"+p` | Presse-papiers système (selon la version de Vim) |
| `ma` puis `'a` | Pose la marque `a` / y retourne |
| `qa` … `q` puis `@a` | Enregistre une macro dans `a` / la rejoue |
| `5@a` | Rejoue 5 fois |

## Configuration : `~/.vimrc`

```vim
set number              " numéros de ligne
set relativenumber      " numéros relatifs
set tabstop=4 shiftwidth=4 expandtab    " tabulations = 4 espaces
set autoindent smartindent
set ignorecase smartcase incsearch hlsearch
set cursorline
set wildmenu            " complétion dans la ligne de commande
set mouse=a
set encoding=utf-8
syntax on
filetype plugin indent on

" YAML : indentation de 2 espaces (important pour Netplan, Compose, GitHub Actions)
autocmd FileType yaml setlocal tabstop=2 shiftwidth=2 expandtab
```

## Scénarios typiques d'administration

```text
Commenter 5 lignes :       Ctrl+v, 4j, I, #, Échap
Éditer un fichier root :   sudo vim /etc/ssh/sshd_config  (ou sudoedit)
Remplacer un mot partout : :%s/ancien/nouveau/gc
Supprimer les commentaires : :g/^#/d
Fichier lu en lecture seule par erreur : :w !sudo tee %
Fichier de verrouillage .swp : fermez l'autre instance ou supprimez le .swp (vim -r pour récupérer)
```

> ⚠️ **Attention** : pour éditer un fichier système, préférez `sudoedit fichier` : l'édition se fait avec vos réglages, et le fichier n'est écrit qu'à la fin.

Voir aussi : [Commandes Linux](commandes-linux.md), [Bash](bash-scripting.md).
