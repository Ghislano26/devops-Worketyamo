# Module 06 — Réseaux pour DevOps

## Pourquoi ce module ?

Les modules Linux ([01](../01-linux-fondamentaux/cours/01-introduction-linux.md) à [04](../04-linux-expert/cours/01-noyau-performance.md))
vous ont appris à administrer une machine. Les incidents de production, eux, se jouent **entre** les machines : un nom qui
ne se résout pas, un port qui n'écoute pas, un pod qui ne sort pas, un certificat expiré. Ce module n'est **pas** un cours de
réseau généraliste : il ne traite que ce qu'un ingénieur DevOps doit maîtriser, avec des exemples tirés de Docker et de Kubernetes.

> Ce module **complète** le [cours réseau de base du module 02](../02-linux-intermediaire/cours/03-reseaux-base.md) sans le répéter : vous y avez vu `ip`, `ping`, `ss`, `dig` ; ici, on explique **comment ça fonctionne** et **comment diagnostiquer**.

## Prérequis

- Modules 00 à 03 terminés (la console, `systemd`, SSH, Bash). Le module 04 (namespaces) est **fortement recommandé** pour l'atelier 03.
- Une VM Ubuntu 24.04 avec accès Internet et `sudo` ; snapshot pris avant chaque atelier.
- Notions de Docker et de Kubernetes **utiles mais non obligatoires** : les cours expliquent ce dont ils ont besoin.
- Les diagrammes sont en **Mermaid** : ils s'affichent directement sur GitHub et GitLab, et dans la plupart des éditeurs Markdown (extension Mermaid pour VS Code).

## Parcours recommandé

| # | Cours | Atelier associé |
|---|---|---|
| 1 | [DNS : les fondamentaux](cours/01-dns-fondamentaux.md) — résolution, enregistrements, TTL, CoreDNS | [Atelier 01 — Résolution DNS](ateliers/atelier-01-dns-resolution.md) |
| 2 | [Ports, sockets et états TCP](cours/02-ports-et-sockets.md) — 5-uplet, états, bind, ports Kubernetes | [Atelier 02 — Ports et services](ateliers/atelier-02-ports-et-services.md) |
| 3 | [Routage, NAT et réseaux de conteneurs](cours/03-routage-et-nat.md) — netfilter, MASQUERADE, DNAT, VXLAN | [Atelier 03 — Routage et NAT](ateliers/atelier-03-routage-nat.md) |
| 4 | [TLS et HTTPS](cours/04-tls-et-https.md) — handshake, certificats, Let's Encrypt, cert-manager, mTLS | *(pratiqué dans l'atelier 04)* |
| 5 | [Diagnostic réseau pour DevOps](cours/05-diagnostic-reseau-devops.md) — méthode, arbre de décision, cas concrets | [Atelier 04 — Diagnostic complet](ateliers/atelier-04-diagnostic-complet.md) |

Chaque cours se termine par un **Résumé** et une section **Pour aller plus loin**. Chaque atelier se déroule sur la VM Ubuntu du
[module 00](../00-installation-ubuntu-vm/README.md), propose un scénario réaliste, des questions de compréhension et une checklist de validation.

## Ce que vous saurez faire à la fin

- Suivre une résolution DNS de la racine à l'enregistrement final et expliquer **pourquoi** un changement n'est pas visible partout.
- Lire l'état d'un socket (`LISTEN`, `TIME_WAIT`, `CLOSE_WAIT`…) et savoir si l'application ou le réseau est en cause.
- Reconstruire à la main le réseau d'un conteneur : namespace, veth, pont, forwarding, **NAT**.
- Expliquer ce que font Docker et `kube-proxy` dans `iptables`.
- Inspecter un certificat, comprendre une chaîne incomplète et automatiser le renouvellement.
- Mener un diagnostic **méthodique** (DNS → TCP → TLS → HTTP → application) et rédiger un rapport d'incident.

## Liens avec le reste du dépôt

| Sujet | Où le revoir |
|---|---|
| Namespaces réseau, cgroups | [Module 04 — Conteneurs](../04-linux-expert/cours/02-conteneurs-namespaces.md) |
| Pare-feu, `ufw`, `sysctl` | [Module 03 — Durcissement](../03-linux-avance/cours/04-securite-durcissement.md) |
| Docker | [Module 05 — Docker](../05-devops-outils/cours/02-docker-fondamentaux.md) |
| Pipelines et déploiement | [Module 05 — CI/CD](../05-devops-outils/cours/03-ci-cd-principes.md) |
| Aide-mémoire | [Commandes Linux](../ressources/cheatsheets/commandes-linux.md) |

> 💡 **Conseil** : gardez deux terminaux ouverts sur la VM pendant les ateliers : l'un pour exécuter, l'autre pour observer (`ss`, `tcpdump`, `journalctl -f`).

> ⚠️ **Attention** : plusieurs ateliers modifient `/etc/hosts`, le pare-feu ou l'IP forwarding. Ils fournissent tous une étape de **nettoyage** : exécutez-la, ou restaurez le snapshot.

## Navigation

- [← Retour au README principal](../README.md)
- [Module 07 — Git branching interactif →](../07-git-branching-interactif/README.md)
