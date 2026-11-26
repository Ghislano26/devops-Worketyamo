# Étape 1 : shebang, mode strict, exécutable

Un bon script commence toujours par un **shebang** et le **mode strict** (voir le [cours Scripting Bash](https://github.com/Ghislano26/devops-Worketyamo/blob/main/03-linux-avance/cours/01-scripting-bash.md)) :

| Élément | Rôle |
|---|---|
| `#!/usr/bin/env bash` | Indique l'interpréteur |
| `set -euo pipefail` | Arrêt sur erreur (`-e`), variable non définie interdite (`-u`), échec d'un pipe détecté (`pipefail`) |

## À vous de jouer

Créez **`~/scripts/sante.sh`** qui :

- affiche `Serveur : <nom d'hôte>` ;
- affiche `Disque / : <pourcentage utilisé>` (via `df --output=pcent /`) ;
- se termine avec le code `0`.

```bash
mkdir -p ~/scripts
cat > ~/scripts/sante.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

echo "Serveur : $(hostname)"
utilise=$(df --output=pcent / | tail -n 1 | tr -d ' ')
echo "Disque / : ${utilise}"
EOF
chmod +x ~/scripts/sante.sh
~/scripts/sante.sh
echo "code retour = $?"
```{{exec}}

Vérifiez la syntaxe sans exécuter, et observez l'exécution pas à pas :

```bash
bash -n ~/scripts/sante.sh && echo "syntaxe OK"
bash -x ~/scripts/sante.sh
```{{exec}}

> Pourquoi des guillemets autour de `"$(hostname)"` et des variables ? Sans eux, une valeur contenant des espaces serait coupée en plusieurs arguments.

Cliquez sur **Vérifier**.
