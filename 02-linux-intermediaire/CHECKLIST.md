# Checklist des compétences — Module 02 : Intermédiaire

Une checklist « admin sys » à cocher au fil du module, comme dans le Linux Upskill Challenge. **Coche une case seulement quand tu sais le faire sans regarder le cours**, sur ton serveur. Chaque compétence renvoie vers le cours ou l'atelier qui la travaille.

> 📌 **À retenir** : une compétence n'est acquise que lorsque tu peux la **refaire de mémoire** dans une VM restaurée. Reviens sur cette liste dans une semaine : quelles cases sais-tu encore cocher ?

## Checklist des compétences — Module 02

- [ ] Je sais lister, prioriser et arrêter des processus (`ps`, `top`, `kill`, `nice`) et choisir le bon signal — *[Cours 01](cours/01-processus-services.md), [Atelier 01](ateliers/atelier-01-processus-systemd.md), [Killercoda 01](ateliers-killercoda/atelier-01-processus-services-killercoda/)*
- [ ] Je sais lancer un processus en arrière-plan et le retrouver (`&`, `jobs`, `nohup`) — *[Cours 01](cours/01-processus-services.md)*
- [ ] Je sais écrire une unité systemd et la piloter (`enable --now`, `status`, `daemon-reload`) — *[Cours 01](cours/01-processus-services.md), [Killercoda 01](ateliers-killercoda/atelier-01-processus-services-killercoda/)*
- [ ] Je sais lire les journaux d'un service (`journalctl -u`, `-f`, `-p`) — *[Cours 01](cours/01-processus-services.md), [Atelier 01](ateliers/atelier-01-processus-systemd.md)*
- [ ] Je sais installer, mettre à jour et supprimer des paquets (`dnf check-update/upgrade/install/remove`) — *[Cours 02](cours/02-gestion-paquets.md), [Killercoda 02](ateliers-killercoda/atelier-02-apt-paquets-killercoda/)*
- [ ] Je sais retrouver l'origine d'un fichier ou d'un binaire (`rpm -qf/-ql`, `dnf info`) — *[Cours 02](cours/02-gestion-paquets.md), [Atelier 02](ateliers/atelier-02-apt-gestion-paquets.md)*
- [ ] Je sais lire la configuration réseau (`ip a`, `ip route`, `nmcli`) et la modifier avec NetworkManager — *[Cours 03](cours/03-reseaux-base.md), [Atelier 03](ateliers/atelier-03-diagnostic-reseau.md)*
- [ ] Je sais diagnostiquer une panne couche par couche (`ping`, `dig`, `ss`, `nc`, `curl`) — *[Cours 03](cours/03-reseaux-base.md), [Atelier 03](ateliers/atelier-03-diagnostic-reseau.md)*
- [ ] Je sais lister les services à l'écoute (`ss -tulpn`) et configurer `firewalld` sans m'enfermer dehors — *[Cours 03](cours/03-reseaux-base.md), [Atelier 03](ateliers/atelier-03-diagnostic-reseau.md)*
- [ ] Je sais générer une clé SSH ed25519, la déployer et me connecter sans mot de passe — *[Cours 04](cours/04-ssh-cles.md), [Atelier 04](ateliers/atelier-04-ssh-securise.md)*
- [ ] Je sais configurer `~/.ssh/config`, transférer avec `scp`/`rsync` et créer un tunnel — *[Cours 04](cours/04-ssh-cles.md), [Atelier 04](ateliers/atelier-04-ssh-securise.md)*
- [ ] Je sais durcir `sshd` (pas de root, pas de mot de passe) et valider avec `sshd -t` avant de recharger — *[Cours 04](cours/04-ssh-cles.md), [Atelier 04](ateliers/atelier-04-ssh-securise.md)*
- [ ] J'ai relevé les 4 défis du module sur mon propre serveur — *[Parcours](PARCOURS.md)*

## Bilan

- Compétences acquises : ___ / 13
- Défis du jour réussis : ___ / 4
- Ce qui m'a bloqué (à relire avant de passer au module suivant) : ______________________

[← Retour au parcours](PARCOURS.md) · [Mon serveur d'entraînement](SERVEUR.md) · [README du module](README.md)
