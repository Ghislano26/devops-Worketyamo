# Étape 2 : valider ses arguments

Un script destiné à la supervision communique par son **code de retour** (voir le [cours](https://github.com/Ghislano26/devops-Worketyamo/blob/main/03-linux-avance/cours/01-scripting-bash.md)) :

| Code | Sens |
|---|---|
| `0` | Tout va bien |
| `1` | Seuil dépassé (alerte) |
| `2` | Mauvais usage (argument absent ou invalide) |

## À vous de jouer

Écrivez **`~/scripts/seuil.sh`** : il reçoit un pourcentage `N` en argument.

- sans argument, ou si `N` n'est pas un entier : message d'erreur sur la **sortie d'erreur** (`>&2`) et code **2** ;
- si `N` < 80 : affiche `OK` et code **0** ;
- sinon : affiche `ALERTE` et code **1**.

```bash
cat > ~/scripts/seuil.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
    echo "Usage : $0 <pourcentage entier>" >&2
    exit 2
fi

if (( $1 < 80 )); then
    echo "OK"
    exit 0
fi
echo "ALERTE"
exit 1
EOF
chmod +x ~/scripts/seuil.sh
```{{exec}}

Testez les quatre cas :

```bash
~/scripts/seuil.sh 10  ; echo "code=$?"
~/scripts/seuil.sh 95  ; echo "code=$?"
~/scripts/seuil.sh     ; echo "code=$?"
~/scripts/seuil.sh abc ; echo "code=$?"
```{{exec}}

> `[[ … =~ ^[0-9]+$ ]]` teste qu'une chaîne ne contient que des chiffres. Les erreurs vont sur `stderr` (`>&2`) pour ne pas polluer la sortie normale.

Cliquez sur **Vérifier**.
