# Scripting Bash

**Durée : ~10 minutes.** Compétence travaillée : écrire un script **fiable** dont on peut exploiter le code de retour.

Prérequis : le cours [Scripting Bash](https://github.com/Ghislano26/devops-Worketyamo/blob/main/03-linux-avance/cours/01-scripting-bash.md).

Un script de production n'est pas une suite de commandes : il doit échouer **proprement et visiblement**.

```bash
bash --version | head -n 1
which shellcheck || (apt-get update -qq && apt-get install -y -qq shellcheck)
```{{exec}}

`shellcheck` détecte les erreurs classiques (guillemets manquants, variables non définies).
