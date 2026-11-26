# Checklist des compétences — Module 04 : Expert

Une checklist « admin sys » à cocher au fil du module, comme dans le Linux Upskill Challenge. **Coche une case seulement quand tu sais le faire sans regarder le cours**, sur ton serveur. Chaque compétence renvoie vers le cours ou l'atelier qui la travaille.

> 📌 **À retenir** : une compétence n'est acquise que lorsque tu peux la **refaire de mémoire** dans une VM restaurée. Reviens sur cette liste dans une semaine : quelles cases sais-tu encore cocher ?

## Checklist des compétences — Module 04

- [ ] Je sais appliquer la méthode USE (Utilisation, Saturation, Erreurs) à CPU, mémoire, disque, réseau — *[Cours 01](cours/01-noyau-performance.md), [Atelier 01](ateliers/atelier-01-tuning-noyau.md)*
- [ ] Je sais lire `vmstat`, `iostat`, `pidstat` et `/proc/pressure` pour trouver un goulot — *[Cours 01](cours/01-noyau-performance.md), [Atelier 01](ateliers/atelier-01-tuning-noyau.md)*
- [ ] Je sais interpréter la mémoire (`available` ≠ `free`, swap, OOM killer) — *[Cours 01](cours/01-noyau-performance.md), [Atelier 01](ateliers/atelier-01-tuning-noyau.md)*
- [ ] Je sais ajuster un paramètre noyau (`sysctl -w`, `/etc/sysctl.d/`) et mesurer l'effet — *[Cours 01](cours/01-noyau-performance.md), [Atelier 01](ateliers/atelier-01-tuning-noyau.md)*
- [ ] Je sais expliquer qu'un conteneur est un processus + namespaces + cgroups — *[Cours 02](cours/02-conteneurs-namespaces.md), [Killercoda 01](ateliers-killercoda/atelier-01-namespaces-cgroups-killercoda/)*
- [ ] Je sais créer des namespaces à la main (`unshare`, `nsenter`, `ip netns`, `veth`) — *[Cours 02](cours/02-conteneurs-namespaces.md), [Atelier 02](ateliers/atelier-02-namespaces-cgroups.md), [Killercoda 01](ateliers-killercoda/atelier-01-namespaces-cgroups-killercoda/)*
- [ ] Je sais limiter CPU, mémoire et processus avec un cgroup v2 — *[Cours 02](cours/02-conteneurs-namespaces.md), [Atelier 02](ateliers/atelier-02-namespaces-cgroups.md), [Killercoda 01](ateliers-killercoda/atelier-01-namespaces-cgroups-killercoda/)*
- [ ] Je sais interroger le journal systemd (`journalctl` : unité, priorité, période, boot) — *[Cours 03](cours/03-observabilite-logs.md), [Atelier 03](ateliers/atelier-03-journalisation-centralisee.md)*
- [ ] Je sais router des journaux avec `rsyslog` et en configurer la rotation (`logrotate`) — *[Cours 03](cours/03-observabilite-logs.md), [Atelier 03](ateliers/atelier-03-journalisation-centralisee.md)*
- [ ] Je sais centraliser des journaux vers un serveur distant avec file d'attente — *[Cours 03](cours/03-observabilite-logs.md), [Atelier 03](ateliers/atelier-03-journalisation-centralisee.md)*
- [ ] J'ai relevé les 3 défis du module sur mon propre serveur — *[Parcours](PARCOURS.md)*

## Bilan

- Compétences acquises : ___ / 11
- Défis du jour réussis : ___ / 3
- Ce qui m'a bloqué (à relire avant de passer au module suivant) : ______________________

[← Retour au parcours](PARCOURS.md) · [Mon serveur d'entraînement](SERVEUR.md) · [README du module](README.md)
