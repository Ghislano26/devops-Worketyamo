#!/usr/bin/env bash
#
# export-killercoda-repos.sh — option B : génère des dépôts Killercoda SÉPARÉS, prêts à être poussés.
#
# Usage :
#   scripts/export-killercoda-repos.sh [--all] [dossier_de_sortie]
#
#   (sans option)  modules 08, 09, 10, 11, 12, 13  →  6 dépôts : docker, kubernetes, monitoring, sre, cicd, iac
#   --all          ajoute les modules Linux 01 à 04  →  + 1 dépôt « linux » (8 scénarios)
#   dossier_de_sortie : défaut = ../worketyamo-killercoda-export (HORS du dépôt courant)
#
# Pour chaque dépôt généré :
#   <dossier>/<dépôt>/
#   ├── structure.json         ← liste des scénarios (chemins à plat, à la racine du dépôt)
#   ├── README.md, LICENSE
#   └── atelier-XX-…/          ← scénarios copiés tels quels (index.json, intro.md, stepN/, finish.md)
#
# Le script ne supprime RIEN : si un dépôt de sortie existe déjà, il s'arrête.
set -euo pipefail

RACINE="$(cd "$(dirname "$0")/.." && pwd)"
TOUT=0
SORTIE=""
for arg in "$@"; do
    case "$arg" in
        --all) TOUT=1 ;;
        -h|--help) sed -n '2,19p' "$0"; exit 0 ;;
        *) SORTIE="$arg" ;;
    esac
done
SORTIE="${SORTIE:-$RACINE/../worketyamo-killercoda-export}"

MODULES="08-docker-approfondi 09-kubernetes-approfondi 10-monitoring-observabilite 11-sre-pratiques 12-cicd 13-iac"
[[ "$TOUT" -eq 1 ]] && MODULES="01-linux-fondamentaux 02-linux-intermediaire 03-linux-avance 04-linux-expert $MODULES"

depot_pour() {                # module -> nom du dépôt de destination
    case "$1" in
        01-*|02-*|03-*|04-*) echo "worketyamo-killercoda-linux" ;;
        08-*) echo "worketyamo-killercoda-docker" ;;
        09-*) echo "worketyamo-killercoda-kubernetes" ;;
        10-*) echo "worketyamo-killercoda-monitoring" ;;
        11-*) echo "worketyamo-killercoda-sre" ;;
        12-*) echo "worketyamo-killercoda-cicd" ;;
        13-*) echo "worketyamo-killercoda-iac" ;;
        *) echo "worketyamo-killercoda-autre" ;;
    esac
}

mkdir -p "$SORTIE"
SORTIE="$(cd "$SORTIE" && pwd)"
DEPOTS=""

# 1. Copie des scénarios
for module in $MODULES; do
    source="$RACINE/$module/ateliers-killercoda"
    [[ -d "$source" ]] || { echo "Dossier absent : $source" >&2; exit 1; }
    depot="$(depot_pour "$module")"
    cible="$SORTIE/$depot"
    case " $DEPOTS " in
        *" $depot "*) ;;                                        # dépôt déjà créé par un module précédent
        *)
            if [[ -e "$cible" ]]; then
                echo "Le dossier $cible existe déjà : supprimez-le ou choisissez un autre dossier de sortie." >&2
                exit 1
            fi
            mkdir -p "$cible"
            : > "$cible/.liste"
            DEPOTS="$DEPOTS $depot"
            ;;
    esac
    for scenario in "$source"/atelier-*/; do
        [[ -f "${scenario}index.json" ]] || continue
        nom="$(basename "$scenario")"
        if [[ -e "$cible/$nom" ]]; then
            echo "Nom de scénario en double dans $depot : $nom" >&2
            exit 1
        fi
        cp -R "$scenario" "$cible/$nom"
        echo "$nom" >> "$cible/.liste"
    done
done

# 2. structure.json, README et licence de chaque dépôt
for depot in $DEPOTS; do
    cible="$SORTIE/$depot"
    {
        echo '{'
        echo '  "items": ['
        total="$(wc -l < "$cible/.liste" | tr -d ' ')"
        n=0
        sort "$cible/.liste" | while read -r nom; do
            n=$((n + 1))
            if [[ "$n" -lt "$total" ]]; then sep=','; else sep=''; fi
            printf '    { "path": "%s" }%s\n' "$nom" "$sep"
        done
        echo '  ]'
        echo '}'
    } > "$cible/structure.json"
    {
        echo "# $depot"
        echo
        echo "Scénarios interactifs [Killercoda](https://killercoda.com/) extraits du dépôt de cours"
        echo "[devops-Worketyamo](https://github.com/Ghislano26/devops-Worketyamo) (Worketyamo)."
        echo
        echo "> ⚠️ Dépôt **généré** par \`scripts/export-killercoda-repos.sh\` : ne modifiez pas les scénarios ici,"
        echo "> modifiez-les dans le dépôt source puis régénérez (voir \`KILLERCODA.md\`, option B)."
        echo
        echo "## Scénarios"
        echo
        sort "$cible/.liste" | while read -r nom; do
            titre="$(python3 -c "import json,sys; print(json.load(open(sys.argv[1]))['title'])" "$cible/$nom/index.json" 2>/dev/null || echo "$nom")"
            echo "- \`$nom\` — $titre"
        done
        echo
        echo "## Licence"
        echo
        echo "Contenu pédagogique sous licence CC BY-SA 4.0 (voir \`LICENSE\`)."
    } > "$cible/README.md"
    cp "$RACINE/LICENSE" "$cible/LICENSE"
    rm -f "$cible/.liste"
    echo "✔ $cible  ($(grep -c '"path"' "$cible/structure.json") scénario(s))"
done

echo
echo "Étapes suivantes (pour chaque dépôt) :"
echo "  cd <dépôt> && git init -b main && git add . && git commit -m \"Scénarios Killercoda\""
echo "  puis créez le dépôt GitHub correspondant et poussez-le (voir KILLERCODA.md, option B)."
