# Ateliers Killercoda — SRE : pratiques

Trois scénarios qui s'exécutent sur **[Killercoda](https://killercoda.com/)** : un serveur Ubuntu (Docker préinstallé) ou un cluster Kubernetes, dans le navigateur. Rien à installer.

| Scénario | Backend | Durée | Niveau | Notions | Cours associés |
|---|---|---|---|---|---|
| [`atelier-01-definir-slo-et-error-budget`](atelier-01-definir-slo-et-error-budget/) | `ubuntu` | ~25 min | ⭐⭐⭐ | SLI en PromQL, `slo.yml`, budget d'erreur, politique de release, `promtool test rules` | [02](../cours/02-slo-sli-error-budget.md) |
| [`atelier-02-postmortem-blameless`](atelier-02-postmortem-blameless/) | `ubuntu` | ~25 min | ⭐⭐⭐ | Postmortem structuré, facteurs contributifs, actions SMART, reformulation sans blâme | [03](../cours/03-gestion-incident-et-oncall.md), [04](../cours/04-postmortem-blameless.md) |
| [`atelier-03-chaos-engineering-basique`](atelier-03-chaos-engineering-basique/) | `kubernetes-kubeadm-1node` | ~30 min | ⭐⭐⭐⭐ | Hypothèse, suppression de pod, auto-réparation, latence `tc netem`, retour arrière | [06](../cours/06-chaos-engineering.md), [07](../cours/07-patterns-fiabilite.md) |

**Lisez le cours associé avant chaque atelier** : l'atelier vérifie vos acquis, il ne réexplique pas la théorie. Les cours 01, 05 et 07 sont purement théoriques (organisation, automatisation, patterns) : à pratiquer avec votre équipe ou votre propre système.

## Backends utilisés

| Backend (`imageid`) | Ateliers | Ce qu'il fournit |
|---|---|---|
| **`ubuntu`** | 1 et 2 | Machine Ubuntu avec **Docker** (l'atelier 1 utilise `promtool`, livré dans l'image `prom/prometheus`, sans lancer de serveur) |
| **`kubernetes-kubeadm-1node`** | 3 | Cluster **kubeadm à un nœud**, `kubectl` configuré |

Le backend est fixé dans le `index.json` de chaque scénario.

## Vérifications

- **Atelier 1** : les `verify.sh` lancent `promtool check rules` et `promtool test rules` (via Docker) sur **votre** fichier `~/slo/slo.rules.yml` : la règle est donc vérifiée **sémantiquement** sur des séries simulées, pas seulement par `grep`.
- **Atelier 2** : contrôles **structurels** (sections, au moins 6 lignes de chronologie, 3 actions au format imposé) et **blameless** (aucun nom de personne, pas de « a causé » / « est responsable »).
- **Atelier 3** : le pod supprimé doit avoir été **remplacé** (nom différent) et le Deployment être revenu à 3 réplicas.

## Publier sur Killercoda

La procédure complète (liaison du dépôt GitHub, `structure.json`, mises à jour, tests) est dans [**`KILLERCODA.md`**](../../KILLERCODA.md) à la racine du dépôt. En résumé :

1. Compte sur <https://killercoda.com/> et profil **Creator** (documentation : <https://killercoda.com/creators>).
2. Lier le dépôt GitHub ; Killercoda lit les scénarios déclarés dans le `structure.json` racine (les 3 scénarios de ce module y figurent).
3. Contrôler en local avant de pousser : `python3 scripts/check-killercoda.py`.

## Lancement en local

Les commandes sont standard. Pour les ateliers 1 et 2 : une VM Ubuntu avec Docker (atelier 1) ; pour l'atelier 3 : un cluster de test (**kind**, **minikube**, **k3s**). Lancez une vérification à la main :

```bash
bash atelier-01-definir-slo-et-error-budget/step1/verify.sh ; echo "code = $?"
```

> ⚠️ **Attention** : l'atelier 3 supprime des pods et modifie le réseau d'un pod (`tc netem`). Ne le faites **jamais** sur un cluster de production.

[← Retour au module 11](../README.md)
