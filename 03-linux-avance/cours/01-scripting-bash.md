# Scripting Bash

## Pourquoi ce cours ?

Un administrateur qui tape trois fois la même suite de commandes a déjà une raison d'écrire un
script. En DevOps, **tout est automatisé** : déploiements, sauvegardes, vérifications de santé.
Bash est le langage universel de cette automatisation : présent sur tous les serveurs, sans rien installer. Mais un
script mal écrit peut supprimer des données ou échouer en silence : ce cours insiste donc sur la **robustesse**.

## 1. Votre premier script

```bash
#!/usr/bin/env bash
# bonjour.sh — premier script
echo "Bonjour $USER, nous sommes le $(date +%d/%m/%Y)"
```

```bash
chmod +x bonjour.sh
./bonjour.sh                 # exécution directe (nécessite x et le shebang)
bash bonjour.sh              # exécution via l'interpréteur (x non requis)
```

- La première ligne `#!/usr/bin/env bash` est le **shebang** : elle indique au noyau quel interpréteur utiliser.
- `#` introduit un commentaire.
- Un script s'exécute dans un **sous-processus** : les variables qu'il définit disparaissent à sa fin (sauf `source script.sh`).

## 2. Variables

```bash
nom="Awa"                 # PAS d'espaces autour du =
age=30
echo "$nom a $age ans"
echo "${nom}_2025"        # accolades : délimitent le nom de la variable
lecture_seule=42; readonly lecture_seule
unset nom                 # supprime
```

| Variable spéciale | Contenu |
|---|---|
| `$0` | Nom du script |
| `$1` … `$9`, `${10}` | Arguments positionnels |
| `$#` | Nombre d'arguments |
| `$@` | Tous les arguments (à utiliser entre guillemets : `"$@"`) |
| `$?` | Code de retour de la dernière commande |
| `$$` | PID du script |
| `$!` | PID du dernier processus lancé en arrière-plan |

### Substitutions de paramètres

```bash
echo "${nom:-inconnu}"       # valeur par défaut si vide ou non définie
echo "${nom:=inconnu}"       # idem, et l'affecte
echo "${nom:?variable requise}"   # erreur et arrêt si vide
fichier="/var/log/syslog.1.gz"
echo "${fichier##*/}"        # supprime le plus long préfixe */ → syslog.1.gz  (basename)
echo "${fichier%.gz}"        # supprime le suffixe → /var/log/syslog.1
echo "${#fichier}"           # longueur
echo "${fichier^^}"          # majuscules
```

### Substitution de commande et arithmétique

```bash
date_jour=$(date +%F)
nb=$(ls | wc -l)
echo $(( nb * 2 + 1 ))       # arithmétique entière
(( nb > 10 )) && echo "beaucoup"
```

### Tableaux

```bash
fruits=("mangue" "ananas" "papaye")
echo "${fruits[0]}"            # premier élément
echo "${fruits[@]}"            # tous
echo "${#fruits[@]}"           # nombre
fruits+=("goyave")
declare -A prix=([mangue]=500 [ananas]=800)   # tableau associatif (Bash ≥ 4)
echo "${prix[mangue]}"
```

> ⚠️ **Attention** : **toujours mettre les variables entre guillemets** (`"$fichier"`). Sans guillemets, un nom contenant un espace est coupé en deux arguments, et `rm $f` avec `f="mon fichier"` supprimerait deux cibles différentes.

## 3. Entrées utilisateur

```bash
read -p "Votre nom : " nom
read -s -p "Mot de passe : " mdp; echo      # -s : saisie masquée
read -r -a mots <<< "un deux trois"         # lecture dans un tableau
```

## 4. Conditions

```bash
if [[ -f /etc/passwd ]]; then
    echo "le fichier existe"
elif [[ -d /etc/passwd ]]; then
    echo "c'est un dossier"
else
    echo "absent"
fi
```

`[[ ... ]]` est la forme recommandée sous Bash (plus sûre que `[ ... ]`).

| Test fichier | Signification |
|---|---|
| `-e` / `-f` / `-d` | existe / fichier ordinaire / dossier |
| `-r` `-w` `-x` | lisible / modifiable / exécutable |
| `-s` | non vide |
| `-L` | lien symbolique |

| Test chaîne | |
|---|---|
| `-z "$s"` / `-n "$s"` | vide / non vide |
| `"$a" == "$b"` | égalité |
| `"$s" == a*` | motif (glob) |
| `"$s" =~ ^[0-9]+$` | expression régulière |

| Test numérique | |
|---|---|
| `-eq` `-ne` | égal / différent |
| `-lt` `-le` `-gt` `-ge` | < ≤ > ≥ |
| ou `(( a < b ))` | forme arithmétique |

```bash
[[ -f "$f" && -r "$f" ]] && echo "lisible"      # ET
[[ "$x" == "a" || "$x" == "b" ]]                # OU
if ! grep -q "root" /etc/passwd; then echo "absent"; fi   # ! = négation
```

### `case`

```bash
case "$1" in
    start)   echo "démarrage" ;;
    stop)    echo "arrêt" ;;
    restart) echo "redémarrage" ;;
    *)       echo "Usage : $0 {start|stop|restart}" >&2; exit 1 ;;
esac
```

## 5. Boucles

```bash
for i in 1 2 3; do echo "n°$i"; done
for i in {1..5}; do echo "$i"; done
for ((i=0; i<3; i++)); do echo "$i"; done
for f in /var/log/*.log; do echo "$f"; done          # glob : sûr avec les espaces
for u in "${utilisateurs[@]}"; do echo "$u"; done

n=0
while (( n < 3 )); do echo "$n"; ((n++)); done

# Lire un fichier ligne par ligne (méthode robuste)
while IFS= read -r ligne; do
    echo "Ligne : $ligne"
done < /etc/hostname

until ping -c1 -W1 8.8.8.8 &>/dev/null; do sleep 2; done   # jusqu'à ce que ça réussisse
```

`break` quitte la boucle, `continue` passe à l'itération suivante.

> ⚠️ **Attention** : ne faites jamais `for f in $(ls)` : le découpage par espaces casse les noms de fichiers. Utilisez un glob (`for f in *`) ou `find -print0`.

## 6. Fonctions

```bash
sauvegarder() {
    local source="$1"        # local : variable limitée à la fonction
    local dest="${2:-/tmp}"
    [[ -d "$source" ]] || { echo "Source introuvable : $source" >&2; return 1; }
    tar czf "$dest/$(basename "$source")-$(date +%F).tar.gz" -C "$(dirname "$source")" "$(basename "$source")"
    echo "OK : $dest"
}

sauvegarder ~/documents /tmp || echo "échec"
```

Une fonction **retourne un code** (`return 0..255`), pas une valeur. Pour « renvoyer » du texte, affichez-le avec `echo` et capturez avec `$(...)`.

## 7. Codes de sortie et gestion d'erreurs

Par convention : **0 = succès**, toute autre valeur = erreur.

```bash
ls /etc > /dev/null; echo $?          # 0
ls /inexistant 2>/dev/null; echo $?   # 2
exit 3                                # quitter le script avec le code 3
```

### Le mode strict (indispensable)

```bash
set -euo pipefail
```

| Option | Effet |
|---|---|
| `-e` | Le script s'arrête à la première commande qui échoue |
| `-u` | Erreur si on utilise une variable non définie (évite `rm -rf "$DIR/"` avec `DIR` vide) |
| `-o pipefail` | Un pipe échoue si **n'importe quelle** commande du pipe échoue |

> 📌 **À retenir** : sans `set -u`, `rm -rf "$DOSSIER/"*` avec `DOSSIER` vide devient `rm -rf /*`. Le mode strict est une assurance.

### `trap` : nettoyer à la sortie

```bash
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT          # exécuté à la fin, quoi qu'il arrive
trap 'echo "interrompu" >&2; exit 130' INT TERM
```

### Redirections avancées

```bash
cmd > sortie.log 2>&1              # stdout + stderr dans un fichier
cmd &> tout.log                    # raccourci Bash
cmd >> journal.log                 # ajout
cmd 2>/dev/null                    # ignorer les erreurs
cmd <<< "texte"                    # here-string
cat <<EOF > conf.txt               # here-document (variables développées)
hôte=$HOSTNAME
EOF
diff <(sort a.txt) <(sort b.txt)   # substitution de processus
exec > >(tee -a script.log) 2>&1   # tout journaliser et afficher
```

## 8. Arguments et options : `getopts`

```bash
usage() { echo "Usage : $0 [-v] [-d dossier] fichier" >&2; exit 1; }
verbose=0; dossier="."
while getopts ":vd:" opt; do
    case "$opt" in
        v) verbose=1 ;;
        d) dossier="$OPTARG" ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))            # les arguments restants commencent à $1
[[ $# -ge 1 ]] || usage
```

## 9. Structure d'un script professionnel

```bash
#!/usr/bin/env bash
#
# sauvegarde.sh — Sauvegarde un dossier avec rotation
# Usage : sauvegarde.sh <source> <destination>
#
set -euo pipefail
IFS=$'\n\t'

readonly LOG="/tmp/$(basename "$0").log"

log()  { printf '%s [%s] %s\n' "$(date '+%F %T')" "$1" "$2" | tee -a "$LOG" >&2; }
die()  { log ERROR "$1"; exit 1; }

main() {
    [[ $# -eq 2 ]] || die "Usage : $0 <source> <destination>"
    local src="$1" dst="$2"
    [[ -d "$src" ]] || die "Source introuvable : $src"
    mkdir -p "$dst"
    local archive="$dst/$(basename "$src")-$(date +%F_%H%M).tar.gz"
    tar czf "$archive" -C "$(dirname "$src")" "$(basename "$src")"
    log INFO "Archive créée : $archive"
}

main "$@"
```

## 10. Qualité : `shellcheck`

```bash
sudo apt install -y shellcheck
shellcheck sauvegarde.sh        # détecte erreurs de guillemets, variables non définies...
bash -n script.sh               # vérifie la syntaxe sans exécuter
bash -x script.sh               # trace chaque commande (débogage)
```

## 11. Planifier : `cron`

```bash
crontab -e                      # édite la table de l'utilisateur
# m  h  jour mois jour_sem  commande
  30 2  *    *    *         /home/etudiant/sauvegarde.sh /srv/data /backup >> /var/log/sauv.log 2>&1
  */5 * *    *    *         /usr/local/bin/verifie-service.sh
crontab -l                      # liste
```

> ⚠️ **Attention** : cron s'exécute avec un `PATH` minimal : utilisez des **chemins absolus** dans vos scripts et dans la table cron.

> 💡 **Conseil** : écrivez d'abord la commande à la main dans le terminal, vérifiez qu'elle fonctionne, puis seulement collez-la dans le script. Passez-le toujours à `shellcheck`.

## Résumé

- Un script commence par un **shebang**, puis `set -euo pipefail`.
- **Guillemets partout** autour des variables ; `[[ ]]` pour les tests.
- Structures : `if/elif/else`, `case`, `for`, `while`, fonctions avec `local`.
- Code de retour : 0 = succès ; `trap … EXIT` nettoie ; `getopts` gère les options.
- Contrôlez avec `shellcheck`, déboguez avec `bash -x`.
- Planifiez avec `cron` (chemins absolus) ou un timer systemd.

## Pour aller plus loin

- `man bash` (sections *Parameter Expansion*, *Conditional Expressions*), Bash Reference Manual.
- Guide de style de Google pour Bash ; « Bash Pitfalls » (mywiki.wooledge.org).
- Cheatsheet : [Bash](../../ressources/cheatsheets/bash-scripting.md).
- Atelier associé : [Scripts d'automatisation](../ateliers/atelier-01-scripts-automatisation.md).
- Cours suivant : [Traitement de texte avancé](02-traitement-texte-avance.md).
