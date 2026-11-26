# Checklist des compétences — Module 03 : Avancé

Une checklist « admin sys » à cocher au fil du module, comme dans le Linux Upskill Challenge. **Coche une case seulement quand tu sais le faire sans regarder le cours**, sur ton serveur. Chaque compétence renvoie vers le cours ou l'atelier qui la travaille.

> 📌 **À retenir** : une compétence n'est acquise que lorsque tu peux la **refaire de mémoire** dans une VM restaurée. Reviens sur cette liste dans une semaine : quelles cases sais-tu encore cocher ?

## Checklist des compétences — Module 03

- [ ] Je sais écrire un script Bash avec shebang, `set -euo pipefail`, fonctions et `trap` — *[Cours 01](cours/01-scripting-bash.md), [Atelier 01](ateliers/atelier-01-scripts-automatisation.md), [Killercoda 01](ateliers-killercoda/atelier-01-scripting-bash-killercoda/)*
- [ ] Je sais gérer arguments (`$1`, `getopts`) et codes de retour (0 / 1 / 2) — *[Cours 01](cours/01-scripting-bash.md), [Killercoda 01](ateliers-killercoda/atelier-01-scripting-bash-killercoda/)*
- [ ] Je sais contrôler la qualité d'un script (`shellcheck`, `bash -n`, `bash -x`) — *[Cours 01](cours/01-scripting-bash.md), [Atelier 01](ateliers/atelier-01-scripts-automatisation.md)*
- [ ] Je sais planifier une tâche (`cron`) avec des chemins absolus — *[Cours 01](cours/01-scripting-bash.md), [Atelier 01](ateliers/atelier-01-scripts-automatisation.md)*
- [ ] Je sais filtrer avec `grep` (regex, `-E`, `-v`, `-c`, `-o`) — *[Cours 02](cours/02-traitement-texte-avance.md), [Atelier 02](ateliers/atelier-02-awk-sed-grep.md), [Killercoda 02](ateliers-killercoda/atelier-02-awk-sed-grep-killercoda/)*
- [ ] Je sais extraire et compter avec `awk` (champs, tableaux associatifs) — *[Cours 02](cours/02-traitement-texte-avance.md), [Atelier 02](ateliers/atelier-02-awk-sed-grep.md), [Killercoda 02](ateliers-killercoda/atelier-02-awk-sed-grep-killercoda/)*
- [ ] Je sais transformer un fichier avec `sed` en gardant une sauvegarde (`-i.bak`) — *[Cours 02](cours/02-traitement-texte-avance.md), [Killercoda 02](ateliers-killercoda/atelier-02-awk-sed-grep-killercoda/)*
- [ ] Je sais décrire les couches du stockage (disque, PV, VG, LV, système de fichiers) — *[Cours 03](cours/03-stockage-lvm.md)*
- [ ] Je sais créer, agrandir à chaud et réduire un volume logique en respectant l'ordre — *[Cours 03](cours/03-stockage-lvm.md), [Atelier 03](ateliers/atelier-03-lvm.md)*
- [ ] Je sais monter un volume durablement par UUID et tester `/etc/fstab` avec `mount -a` — *[Cours 03](cours/03-stockage-lvm.md), [Atelier 03](ateliers/atelier-03-lvm.md)*
- [ ] Je sais configurer un pare-feu `ufw`, `fail2ban` et durcir `sysctl` — *[Cours 04](cours/04-securite-durcissement.md), [Atelier 04](ateliers/atelier-04-durcissement-serveur.md)*
- [ ] Je sais auditer un serveur (`lynis`, comptes, ports, setuid) et mesurer l'avant/après — *[Cours 04](cours/04-securite-durcissement.md), [Atelier 04](ateliers/atelier-04-durcissement-serveur.md)*
- [ ] J'ai relevé les 4 défis du module sur mon propre serveur — *[Parcours](PARCOURS.md)*

## Bilan

- Compétences acquises : ___ / 13
- Défis du jour réussis : ___ / 4
- Ce qui m'a bloqué (à relire avant de passer au module suivant) : ______________________

[← Retour au parcours](PARCOURS.md) · [Mon serveur d'entraînement](SERVEUR.md) · [README du module](README.md)
