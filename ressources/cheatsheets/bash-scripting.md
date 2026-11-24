# Cheatsheet — Scripting Bash

Détails et exemples commentés : [cours Scripting Bash](../../03-linux-avance/cours/01-scripting-bash.md).

## Squelette de script robuste

```bash
#!/usr/bin/env bash
#
# nom.sh — description en une ligne
# Usage : nom.sh [-v] <argument>
#
set -euo pipefail

log() { printf '%s [%s] %s\n' "$(date '+%F %T')" "$1" "$2" >&2; }
die() { log ERREUR "$1"; exit 1; }

main() {
    [[ $# -ge 1 ]] || die "Usage : $0 <argument>"
    local arg="$1"
    log INFO "Traitement de $arg"
}

main "$@"
```

```bash
chmod +x nom.sh && ./nom.sh arg      # exécution
bash -n nom.sh                       # vérifie la syntaxe
bash -x nom.sh                       # trace
shellcheck nom.sh                    # analyse statique
```

## Variables

```bash
nom="Awa"                      # pas d'espace autour du =
echo "$nom" "${nom}_suffixe"   # TOUJOURS entre guillemets
readonly PI=3
unset nom
export VAR=valeur              # visible des sous-processus
local x=1                      # dans une fonction
resultat=$(commande)           # capture de la sortie
n=$((a + b * 2))               # arithmétique
```

| Variable | Sens |
|---|---|
| `$0` | Nom du script |
| `$1` … `${10}` | Arguments |
| `$#` | Nombre d'arguments |
| `"$@"` | Tous les arguments (un par mot) |
| `"$*"` | Tous les arguments en une seule chaîne |
| `$?` | Code retour précédent |
| `$$` | PID du shell |
| `$!` | PID du dernier job en arrière-plan |
| `$USER` `$HOME` `$PWD` `$HOSTNAME` | Environnement |
| `$RANDOM` | Entier aléatoire |

### Substitutions

| Syntaxe | Effet |
|---|---|
| `${v:-défaut}` | Valeur par défaut si vide |
| `${v:=défaut}` | Idem et affecte |
| `${v:?message}` | Erreur si vide |
| `${#v}` | Longueur |
| `${v#préfixe}` / `${v##préfixe}` | Supprime le plus court / long préfixe |
| `${v%suffixe}` / `${v%%suffixe}` | Supprime le plus court / long suffixe |
| `${v/a/b}` / `${v//a/b}` | Remplace 1re / toutes occurrences |
| `${v^^}` / `${v,,}` | Majuscules / minuscules |
| `${v:2:3}` | Sous-chaîne (position 2, longueur 3) |

### Tableaux

```bash
t=(a b c)
t+=(d)
echo "${t[0]}" "${t[@]}" "${#t[@]}"
for e in "${t[@]}"; do echo "$e"; done
declare -A prix=([mangue]=500 [ananas]=800)
echo "${prix[mangue]}"
for k in "${!prix[@]}"; do echo "$k=${prix[$k]}"; done
```

## Guillemets

| Forme | Comportement |
|---|---|
| `"..."` | Variables et `$(...)` développées |
| `'...'` | Texte littéral |
| `\x` | Échappe un caractère |
| `$'a\tb'` | Séquences d'échappement (`\n`, `\t`) |

## Conditions

```bash
if [[ -f "$f" && -r "$f" ]]; then
    echo "lisible"
elif [[ -d "$f" ]]; then
    echo "dossier"
else
    echo "autre"
fi

[[ -n "$x" ]] && echo "non vide"
(( n > 10 )) && echo "grand"
cmd && echo "ok" || echo "échec"
if ! grep -q "x" f; then echo "absent"; fi
```

| Fichiers | | Chaînes | | Nombres | |
|---|---|---|---|---|---|
| `-e` existe | `-d` dossier | `-z` vide | `-n` non vide | `-eq` `-ne` | `==` `!=` |
| `-f` fichier | `-L` lien | `==` `!=` | `=~` regex | `-lt` `-le` | `<` `<=` (en `(( ))`) |
| `-r` `-w` `-x` | `-s` non vide | `<` `>` (ordre) | `==` motif glob | `-gt` `-ge` | `>` `>=` (en `(( ))`) |

### `case`

```bash
case "$1" in
    start|up)  echo "démarrage" ;;
    stop)      echo "arrêt" ;;
    [0-9]*)    echo "nombre" ;;
    *)         echo "inconnu" >&2; exit 1 ;;
esac
```

## Boucles

```bash
for i in {1..5}; do echo "$i"; done
for ((i=0; i<3; i++)); do echo "$i"; done
for f in *.log; do [[ -e "$f" ]] || continue; echo "$f"; done
for arg in "$@"; do echo "$arg"; done

while (( n < 3 )); do ((n++)); done
until ping -c1 -W1 8.8.8.8 &>/dev/null; do sleep 2; done

while IFS= read -r ligne; do echo "$ligne"; done < fichier
while IFS=: read -r user _ uid _; do echo "$user=$uid"; done < /etc/passwd

find . -name "*.txt" -print0 | while IFS= read -r -d '' f; do echo "$f"; done
```

`break` quitte, `continue` passe à la suite, `break 2` quitte deux boucles.

> ⚠️ **Attention** : jamais `for f in $(ls)` ; utilisez un glob ou `find -print0`.

## Fonctions

```bash
saluer() {
    local nom="${1:-monde}"
    echo "Bonjour $nom"
    return 0
}
saluer Awa
msg=$(saluer Awa)        # capture ce que la fonction affiche
saluer || echo "échec"   # utilise le code retour
```

## Redirections

| Syntaxe | Effet |
|---|---|
| `> f` / `>> f` | stdout : écrase / ajoute |
| `2> f` / `2>> f` | stderr |
| `&> f` | stdout + stderr |
| `> f 2>&1` | idem, forme portable |
| `2>&1 \| cmd` | Envoie stdout et stderr dans le tube |
| `< f` | stdin depuis un fichier |
| `<<< "texte"` | *Here-string* |
| `<<EOF … EOF` | *Here-document* (variables développées) |
| `<<'EOF' … EOF` | *Here-document* littéral (pas de développement) |
| `> /dev/null` | Jeter |
| `<(cmd)` | Substitution de processus : `diff <(sort a) <(sort b)` |
| `exec > >(tee -a log) 2>&1` | Journaliser toute la sortie du script |

## Codes de sortie et erreurs

```bash
exit 0          # succès
exit 1          # erreur générique
cmd || exit 1   # quitte si échec
set -euo pipefail
trap 'rm -rf "$tmp"' EXIT                  # nettoyage à la sortie
trap 'echo "Interrompu" >&2; exit 130' INT TERM
tmp=$(mktemp -d)
```

| Code | Sens usuel |
|---|---|
| 0 | Succès |
| 1 | Erreur générale |
| 2 | Mauvais usage |
| 126 | Non exécutable |
| 127 | Commande introuvable |
| 130 | Interrompu (Ctrl+C) |
| 137 | Tué (SIGKILL / OOM) |

## Options avec `getopts`

```bash
while getopts ":vk:" opt; do
    case "$opt" in
        v) verbeux=1 ;;
        k) nombre="$OPTARG" ;;
        :) die "L'option -$OPTARG exige un argument" ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))
```

## Entrées utilisateur

```bash
read -r -p "Nom : " nom
read -r -s -p "Mot de passe : " mdp; echo
read -r -p "Continuer ? [o/N] " rep; [[ "$rep" =~ ^[oO]$ ]] || exit 0
```

## Texte et fichiers dans un script

```bash
mapfile -t lignes < fichier              # fichier → tableau
nb=$(wc -l < fichier)
date +%F ; date +%F_%H%M%S              # 2025-11-24 ; 2025-11-24_091530
basename /a/b/c.txt ; dirname /a/b/c.txt
[[ $EUID -eq 0 ]] || die "Exécutez avec sudo"
command -v docker >/dev/null || die "docker manquant"
flock -n /tmp/mon.lock cmd              # empêche l'exécution simultanée
```

## Planification : cron

```text
# m  h  jour  mois  jour_sem   commande
  0  2   *     *      *        /usr/local/bin/sauvegarde.sh >> /var/log/sauv.log 2>&1
 */5 *   *     *      *        /usr/local/bin/sonde.sh
  0  9   *     *     1-5       /usr/local/bin/rapport.sh
```

```bash
crontab -e ; crontab -l
```

> 💡 **Conseil** : dans cron, utilisez des **chemins absolus** : le `PATH` y est minimal.

## Pièges classiques

| Piège | Correction |
|---|---|
| `$var` sans guillemets | `"$var"` |
| `[ $a = $b ]` | `[[ "$a" == "$b" ]]` |
| `a = 1` (espaces) | `a=1` |
| `cd dossier` non vérifié | `cd dossier \|\| exit 1` |
| `rm -rf "$D/"*` avec `D` vide | `set -u` et `${D:?}` |
| `cat f \| grep x` | `grep x f` |
| `for f in $(ls)` | `for f in *` |
| `echo` avec options/backslashes | `printf '%s\n' "$x"` |

Voir aussi : [Commandes Linux](commandes-linux.md), [Vim](vim.md).
