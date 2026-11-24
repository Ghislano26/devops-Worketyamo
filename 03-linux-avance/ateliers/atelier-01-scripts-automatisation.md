# Atelier 01 — Scripts d'automatisation Bash

## 🎯 Objectifs

- Écrire des scripts robustes (`set -euo pipefail`, fonctions, `trap`, `getopts`).
- Automatiser une sauvegarde avec rotation et un contrôle de santé du serveur.
- Planifier l'exécution avec `cron`.
- Contrôler la qualité avec `shellcheck`.

## 📋 Prérequis

- Modules 01 et 02 terminés.
- Cours lu : [Scripting Bash](../cours/01-scripting-bash.md).
- Paquets : `shellcheck` (`sudo apt install -y shellcheck`).

## 🧪 Scénario

*Kamer Logistics* veut deux outils maison : (1) un script de **sauvegarde** quotidienne du dossier
`/srv/data` avec conservation des 5 dernières archives ; (2) un script de **santé** qui vérifie l'espace
disque, la mémoire et l'état d'un service, et signale tout problème par un code de retour exploitable
par un outil de supervision.

## Préparation

```bash
mkdir -p ~/atelier-bash/{bin,data,backup,logs}
cd ~/atelier-bash
for i in 1 2 3; do echo "colis $i" > data/colis-$i.txt; done
ls data
```

## Étapes

### Étape 1 — Un script minimal et exécutable

```bash
cat > bin/bonjour.sh <<'EOF'
#!/usr/bin/env bash
echo "Bonjour $USER, nous sommes le $(date +%d/%m/%Y) sur $(hostname)"
EOF
chmod +x bin/bonjour.sh
./bin/bonjour.sh
```

> ❓ **Question 1** : À quoi sert le shebang ? Que se passe-t-il si vous retirez `chmod +x` et lancez `./bin/bonjour.sh` ?

### Étape 2 — Le piège des variables non protégées

```bash
cat > bin/piege.sh <<'EOF'
#!/usr/bin/env bash
f="mon fichier.txt"
touch "$f"
ls -l $f          # SANS guillemets : deux arguments !
ls -l "$f"        # AVEC guillemets : un seul argument
rm -f "$f"
EOF
chmod +x bin/piege.sh && ./bin/piege.sh
shellcheck bin/piege.sh
```

> ❓ **Question 2** : Que signale `shellcheck` ? Pourquoi `rm $f` sans guillemets serait-il dangereux ?

### Étape 3 — Le script de sauvegarde (version robuste)

```bash
cat > bin/sauvegarde.sh <<'EOF'
#!/usr/bin/env bash
#
# sauvegarde.sh — archive un dossier et conserve les N dernières copies
# Usage : sauvegarde.sh [-k nombre] <source> <destination>
#
set -euo pipefail

CONSERVER=5

log() { printf '%s [%s] %s\n' "$(date '+%F %T')" "$1" "$2" >&2; }
die() { log ERREUR "$1"; exit 1; }
usage() { echo "Usage : $0 [-k nombre] <source> <destination>" >&2; exit 2; }

while getopts ":k:" opt; do
    case "$opt" in
        k) CONSERVER="$OPTARG" ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))
[[ $# -eq 2 ]] || usage

SRC="$1"
DST="$2"
[[ -d "$SRC" ]] || die "Source introuvable : $SRC"
[[ "$CONSERVER" =~ ^[0-9]+$ ]] || die "Le nombre à conserver doit être un entier"
mkdir -p "$DST"

NOM="$(basename "$SRC")"
ARCHIVE="$DST/${NOM}-$(date +%F_%H%M%S).tar.gz"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

log INFO "Sauvegarde de $SRC vers $ARCHIVE"
tar czf "$TMP" -C "$(dirname "$SRC")" "$NOM"
mv "$TMP" "$ARCHIVE"
log INFO "Archive créée : $(du -h "$ARCHIVE" | cut -f1)"

# Rotation : ne garder que les N plus récentes
mapfile -t anciennes < <(ls -1t "$DST"/"${NOM}"-*.tar.gz | tail -n +$((CONSERVER + 1)))
for f in "${anciennes[@]}"; do
    log INFO "Suppression de l'ancienne archive : $f"
    rm -f -- "$f"
done
EOF
chmod +x bin/sauvegarde.sh
shellcheck bin/sauvegarde.sh && echo "shellcheck OK"
```

> ❓ **Question 3** : Pourquoi écrit-on d'abord dans un fichier temporaire puis `mv` ? *(Indice : que se passe-t-il si le script est interrompu pendant `tar` ?)*
> ❓ **Question 4** : Que fait chaque lettre de `set -euo pipefail` ?

### Étape 4 — Tester le script

```bash
./bin/sauvegarde.sh                                     # erreur d'usage attendue
./bin/sauvegarde.sh data backup ; echo "code=$?"
./bin/sauvegarde.sh /inexistant backup ; echo "code=$?"   # échec attendu (code 1)
for i in 1 2 3 4 5 6 7; do sleep 1; ./bin/sauvegarde.sh -k 5 data backup 2>/dev/null; done
ls -1 backup | wc -l                                    # doit afficher 5
tar tzf "$(ls -1t backup/*.tar.gz | head -1)"           # contenu de la dernière archive
```

### Étape 5 — Le script de santé

```bash
cat > bin/sante.sh <<'EOF'
#!/usr/bin/env bash
#
# sante.sh — contrôle disque, mémoire et service. Code retour : 0 OK, 1 avertissement, 2 critique
#
set -euo pipefail

SEUIL_DISQUE=80
SEUIL_MEM=90
SERVICE="${1:-ssh}"
statut=0

alerte() {                       # alerte <niveau 1|2> <message>
    echo "[$( [[ $1 -eq 2 ]] && echo CRITIQUE || echo ATTENTION )] $2"
    (( $1 > statut )) && statut=$1
    return 0
}

# 1. Disque (racine)
utilise=$(df --output=pcent / | tail -1 | tr -dc '0-9')
if   (( utilise >= 95 )); then alerte 2 "Disque / à ${utilise} %"
elif (( utilise >= SEUIL_DISQUE )); then alerte 1 "Disque / à ${utilise} %"
else echo "[OK] Disque / à ${utilise} %"; fi

# 2. Mémoire
total=$(free -m | awk '/^Mem:/ {print $2}')
dispo=$(free -m | awk '/^Mem:/ {print $7}')
pct=$(( (total - dispo) * 100 / total ))
if (( pct >= SEUIL_MEM )); then alerte 1 "Mémoire utilisée à ${pct} %"; else echo "[OK] Mémoire à ${pct} %"; fi

# 3. Service
if systemctl is-active --quiet "$SERVICE"; then
    echo "[OK] Service $SERVICE actif"
else
    alerte 2 "Service $SERVICE inactif"
fi

# 4. Charge CPU
charge=$(cut -d' ' -f1 /proc/loadavg)
cpus=$(nproc)
echo "[INFO] Charge 1 min : $charge pour $cpus vCPU"

exit "$statut"
EOF
chmod +x bin/sante.sh
shellcheck bin/sante.sh
./bin/sante.sh ssh ; echo "code retour = $?"
./bin/sante.sh service-inexistant ; echo "code retour = $?"
```

> ❓ **Question 5** : Pourquoi le code de retour est-il plus utile qu'un simple message pour un outil de supervision ?

### Étape 6 — Utiliser `trap` et déboguer

```bash
cat > bin/piege-trap.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
tmp=$(mktemp -d)
trap 'echo "Nettoyage de $tmp"; rm -rf "$tmp"' EXIT
echo "Travail dans $tmp"
sleep 30
EOF
chmod +x bin/piege-trap.sh
./bin/piege-trap.sh
# Appuyez sur Ctrl+C avant la fin : le message « Nettoyage » doit apparaître
bash -x bin/bonjour.sh                  # mode trace
```

### Étape 7 — Planifier avec `cron`

```bash
crontab -l 2>/dev/null || echo "(aucune table cron)"
( crontab -l 2>/dev/null; echo "* * * * * $HOME/atelier-bash/bin/sauvegarde.sh -k 5 $HOME/atelier-bash/data $HOME/atelier-bash/backup >> $HOME/atelier-bash/logs/cron.log 2>&1" ) | crontab -
crontab -l
sleep 70
cat logs/cron.log
ls backup | wc -l
```

> ❓ **Question 6** : Pourquoi utilise-t-on des chemins **absolus** dans une tâche cron ?

Retirez la tâche une fois le test fait :

```bash
crontab -l | grep -v "atelier-bash" | crontab -
crontab -l
```

> 💡 **Conseil** : si `crontab -l` devient vide, le message « no crontab » est normal.

## ✅ Validation

- [ ] `shellcheck` ne signale aucune erreur sur `sauvegarde.sh` et `sante.sh`.
- [ ] Après 7 exécutions, `backup/` contient exactement **5** archives.
- [ ] `sante.sh ssh` renvoie 0 ; `sante.sh service-inexistant` renvoie 2.
- [ ] Une source inexistante fait échouer la sauvegarde avec le code 1 et un message clair.
- [ ] Le `trap` nettoie le dossier temporaire lors d'un `Ctrl+C`.
- [ ] La tâche cron a produit au moins une archive et une ligne dans `logs/cron.log`, puis a été retirée.

## 💡 Pour aller plus loin

- **Défi 1** : ajoutez une option `-v` (verbeux) et `-n` (simulation, *dry-run*) à `sauvegarde.sh`.
- **Défi 2** : faites envoyer un e-mail ou écrire dans `logger -t sante` lorsqu'un seuil est dépassé (`journalctl -t sante`).
- **Défi 3** : remplacez cron par un **timer systemd** (`sauvegarde.service` + `sauvegarde.timer`).
- **Défi 4** : écrivez `deploy.sh` qui rejette l'exécution en root (`[[ $EUID -ne 0 ]]`) et verrouille l'exécution simultanée avec `flock`.

Atelier suivant : [awk, sed, grep](atelier-02-awk-sed-grep.md).
