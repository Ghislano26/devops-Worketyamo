# Introduction à Linux et à la console

## Pourquoi ce cours ?

Linux fait tourner la grande majorité des serveurs web, des services cloud, des
conteneurs et des supercalculateurs. Un ingénieur DevOps passe son temps à
administrer des machines Linux, la plupart du temps **sans interface graphique**.
Comprendre ce qu'est Linux, et surtout ce qu'est la console, est la base de tout le reste.

## 1. Linux, noyau et distributions

**Linux** désigne strictement le **noyau** (*kernel*), créé par Linus Torvalds en 1991. Le noyau est
le cœur du système : il gère le processeur, la mémoire, les disques et le réseau, et
sert d'intermédiaire entre les logiciels et le matériel.

Un système utilisable ajoute autour du noyau des outils (le projet GNU : `ls`, `cp`, `bash`…), un gestionnaire de paquets, etc. Cet
ensemble s'appelle une **distribution**.

```text
┌────────────────────────────────────────────┐
│  Applications (navigateur, nginx, docker)  │
├────────────────────────────────────────────┤
│  Shell (bash) · Outils GNU (ls, cp, grep)  │
├────────────────────────────────────────────┤
│  Bibliothèque C (glibc) · Appels système   │
├────────────────────────────────────────────┤
│  NOYAU LINUX (processus, mémoire, FS, net) │
├────────────────────────────────────────────┤
│  Matériel (CPU, RAM, disque, carte réseau) │
└────────────────────────────────────────────┘
```

| Famille | Exemples | Gestionnaire de paquets | Usage typique |
|---|---|---|---|
| Debian | Debian, **Ubuntu**, Linux Mint | `apt` (`.deb`) | Serveurs, postes de travail |
| Red Hat | RHEL, Rocky Linux, Fedora | `dnf` (`.rpm`) | Entreprise |
| Arch | Arch, Manjaro | `pacman` | Utilisateurs avancés |
| Alpine | Alpine | `apk` | Conteneurs (très léger) |

> 📌 **À retenir** : Linux = noyau. Ubuntu = distribution (noyau + outils + paquets + politique de mises à jour). Dans ce cours, nous utilisons **Ubuntu 24.04 LTS** (nom de code « Noble Numbat »).

## 2. Philosophie Unix

Linux hérite d'Unix, dont la philosophie se résume ainsi :

1. Un programme fait **une seule chose**, et la fait bien.
2. Les programmes **coopèrent** : la sortie de l'un devient l'entrée de l'autre (les *pipes*).
3. Les données sont du **texte** : simple à lire, à filtrer, à transformer.
4. **Tout est fichier** : un disque, un terminal, un processus ont une représentation dans l'arborescence.

Cette dernière idée est fondamentale. Exemple : `/dev/sda` représente un disque, `/proc/cpuinfo` expose des informations du noyau.

## 3. Terminal, console, shell : trois notions distinctes

| Terme | Définition |
|---|---|
| **Terminal** | La fenêtre (ou l'écran) où vous tapez et lisez du texte. |
| **Console** | À l'origine, le terminal physique relié directement à la machine. Par extension, l'écran texte d'un serveur. |
| **Shell** | Le programme qui **interprète** vos commandes. Sous Ubuntu, c'est **Bash** (*Bourne Again SHell*). |

```text
Vous ──► Terminal ──► Shell (bash) ──► Noyau ──► Matériel
```

Pour savoir quel shell vous utilisez :

```bash
echo $SHELL        # shell de connexion par défaut : /bin/bash
echo $0            # shell en cours d'exécution
```

## 4. Anatomie du prompt

```text
etudiant@ubuntu-devops:~/projets$
└───┬──┘ └─────┬─────┘ └───┬───┘│
 utilisateur  machine   répertoire  └─ $ = utilisateur normal ; # = root
```

> ⚠️ **Attention** : un prompt qui se termine par `#` indique une session **root**. Chaque commande
> peut alors tout détruire sans demander confirmation. Préférez `sudo` ponctuel.

## 5. Anatomie d'une commande

```text
commande   [options]   [arguments]
   ls         -l          /etc
```

- **Option courte** : `-l` (un tiret, une lettre). Plusieurs se combinent : `-alh`.
- **Option longue** : `--all` (deux tirets, un mot).
- **Argument** : la cible de la commande (fichier, dossier, texte).

```bash
ls                 # liste le dossier courant
ls -l              # format détaillé
ls -l /etc         # format détaillé, dossier /etc
ls --help          # aide courte intégrée
```

## 6. Trouver de l'aide : `man`, `--help`, `apropos`

```bash
man ls               # manuel complet (q pour quitter, / pour chercher, n = suivant)
ls --help | less     # aide courte paginée
apropos "copy file"  # cherche une commande par mot-clé (nécessite man-db)
type cd              # indique si c'est une commande interne (builtin) ou un programme
help cd              # aide des commandes internes de Bash
```

Les pages de manuel sont rangées en **sections** : 1 (commandes), 5 (formats de fichiers), 8 (administration)… `man 5 passwd` ouvre le format du fichier `/etc/passwd`, alors que `man passwd` décrit la commande.

> 💡 **Conseil** : apprenez à lire un `man` avant de chercher sur Internet. La syntaxe `[option]` signifie facultatif, `<fichier>` obligatoire, `a|b` choix.

## 7. Compétences de survie dans le terminal

| Raccourci | Effet |
|---|---|
| `Tab` | Complétion automatique (appuyer deux fois liste les possibilités) |
| `↑` / `↓` | Parcourir l'historique |
| `Ctrl+R` | Recherche dans l'historique |
| `Ctrl+C` | Interrompre la commande en cours |
| `Ctrl+D` | Fin d'entrée / se déconnecter |
| `Ctrl+L` | Effacer l'écran (équivaut à `clear`) |
| `Ctrl+A` / `Ctrl+E` | Début / fin de ligne |
| `Ctrl+W` | Effacer le mot précédent |
| `!!` | Rejouer la dernière commande (`sudo !!` pour la relancer avec sudo) |

```bash
history | tail -5     # cinq dernières commandes
```

## 8. Premières commandes d'identification

```bash
whoami        # qui suis-je ?
hostname      # nom de la machine
uname -a      # noyau et architecture
date          # date et heure
uptime        # depuis quand tourne la machine, charge
pwd           # où suis-je ?
```

## Résumé

- Linux est un **noyau** ; Ubuntu est une **distribution** qui l'embarque avec des outils et des paquets.
- Philosophie Unix : petits outils, texte, pipes, « tout est fichier ».
- Terminal ≠ shell : le **shell** (Bash) interprète vos commandes.
- Une commande = `commande [options] [arguments]`.
- Aide : `man`, `--help`, `help`, `apropos`, `type`.
- Raccourcis essentiels : `Tab`, `Ctrl+C`, `Ctrl+R`, `↑`.

## Pour aller plus loin

- Lire `man bash` (sections *INVOCATION* et *SHELL BUILTIN COMMANDS*).
- Histoire : Unix (1969), GNU (1983), Linux (1991).
- Site officiel : <https://ubuntu.com> et <https://www.kernel.org>.
- Cours suivant : [Le système de fichiers](02-systeme-fichiers.md).
