# Ateliers Killercoda — Monitoring & Observabilité

Quatre scénarios qui s'exécutent sur **[Killercoda](https://killercoda.com/)** : un vrai serveur Ubuntu (Docker préinstallé) ou un vrai cluster Kubernetes, dans le navigateur. Rien à installer, rien à casser sur votre ordinateur.

| Scénario | Backend | Durée | Niveau | Notions | Cours associés |
|---|---|---|---|---|---|
| [`atelier-01-prometheus-grafana-ubuntu`](atelier-01-prometheus-grafana-ubuntu/) | `ubuntu` | ~25 min | ⭐⭐ | node_exporter, Prometheus (`/targets`), Grafana (provisioning, dashboard 1860) | [02](../cours/02-prometheus-fondamentaux.md), [04](../cours/04-grafana-visualisation.md) |
| [`atelier-02-promql-requetes`](atelier-02-promql-requetes/) | `ubuntu` | ~20 min | ⭐⭐⭐ | `rate()`, `avg`, `topk`, `sort_desc`, API `/api/v1/query` | [03](../cours/03-promql-et-metriques.md) |
| [`atelier-03-alertes-avec-alertmanager`](atelier-03-alertes-avec-alertmanager/) | `ubuntu` | ~25 min | ⭐⭐⭐⭐ | Règle `HighCPUUsage`, `promtool`, `stress-ng`, pending → firing, Alertmanager | [05](../cours/05-alertmanager-alertes.md) |
| [`atelier-04-monitoring-kubernetes`](atelier-04-monitoring-kubernetes/) | `kubernetes-kubeadm-1node` | ~30 min | ⭐⭐⭐⭐ | Helm, `kube-prometheus-stack`, Grafana, kube-state-metrics | [02](../cours/02-prometheus-fondamentaux.md), [04](../cours/04-grafana-visualisation.md) |

**Lisez le cours associé avant chaque atelier** : l'atelier vérifie vos acquis, il ne réexplique pas la théorie. Les ateliers 1 à 3 s'enchaînent, mais chacun est **autonome** (les ateliers 2 et 3 fournissent leur propre script de mise en place).

## Choisir le backend

| Backend (`imageid`) | Quand | Ce qu'il fournit |
|---|---|---|
| **`ubuntu`** | Ateliers 1, 2, 3 | Machine Ubuntu avec **Docker** : toute la pile tourne en conteneurs (`--network host`) |
| **`kubernetes-kubeadm-1node`** | Atelier 4 | Cluster **kubeadm à un nœud**, `kubectl` configuré (Helm installé par l'atelier au besoin) |

Le backend est fixé dans le `index.json` de chaque scénario : `"backend": {"imageid": "ubuntu"}` ou `"kubernetes-kubeadm-1node"`.

## Structure d'un scénario

```text
atelier-0X-nom/
├── index.json          # titre, difficulté, durée, étapes, image de l'environnement
├── intro.md            # objectif, environnement, mise en place
├── step1/
│   ├── text.md         # instructions pas à pas (commandes cliquables)
│   └── verify.sh       # vérification (code de retour 0 = étape réussie)
├── step2/ …            # (l'atelier 1 comporte trois étapes)
└── finish.md           # résumé, défi bonus, liens vers les cours
```

Dans les `text.md`, un bloc ` ```bash … ```{{exec}} ` s'exécute d'un clic, ` ```{{copy}} ` le copie. Le bouton **Vérifier** lance `verify.sh` : code **0** = étape réussie ; sinon le message indique ce qui manque (les scripts utilisent `curl`, `jq`, `docker`, `kubectl`).

## Publier ces scénarios sur Killercoda

1. Créez un compte sur <https://killercoda.com/> (connexion GitHub possible), puis ouvrez votre profil → **Creator**.
2. **Liez ce dépôt GitHub** à votre profil (dépôt public, ou accès accordé via la GitHub App de Killercoda). Les scénarios sont lus dans le dépôt et mis à jour à chaque *push*.
3. Le backend est lu dans `index.json` : **`ubuntu`** ou **`kubernetes-kubeadm-1node`**.
4. Lancez le scénario depuis votre page Creator ; vous pouvez **prévisualiser** vos modifications avant publication.

> ⚠️ **Attention** : Killercoda détecte les scénarios selon la **structure du dépôt** (dossiers contenant un `index.json`, éventuellement déclarés par un `structure.json`). Ces scénarios sont rangés sous `10-monitoring-observabilite/ateliers-killercoda/`. Si la plateforme ne les trouve pas à cet emplacement, consultez la documentation « Creators » (<https://killercoda.com/creators>) : il faudra peut-être déclarer ces chemins dans un `structure.json` ou placer les dossiers `atelier-0X-*` à la racine d'un dépôt dédié.

## Accéder aux interfaces web

Sur Killercoda, utilisez le menu **Traffic / Ports** pour ouvrir un port de la machine dans le navigateur :

| Interface | Port |
|---|---|
| Prometheus | `9090` |
| Alertmanager | `9093` |
| Grafana | `3000` (identifiants `admin` / `admin`) |
| node_exporter (métriques brutes) | `9100` |

Tous les ateliers se font **entièrement en ligne de commande** (API HTTP) : l'interface web est un confort, pas une obligation.

## Conseils pour un lancement en local

Les commandes sont standard : vous pouvez suivre les `text.md` sur votre propre VM Ubuntu (Docker installé : [module 08](../../08-docker-approfondi/README.md)) ou sur un cluster de test (**kind**, **minikube**, **k3s**) pour l'atelier 4.

- **Ressources** : Prometheus + Grafana + Alertmanager demandent environ 1 à 2 Go de RAM ; `kube-prometheus-stack` environ 2 à 3 Go de plus. Sur une VM de 4 Go, **supprimez la pile précédente** avant de lancer la suivante : `docker rm -f $(docker ps -aq)`.
- **Ports** : les conteneurs utilisent `--network host` ; si un port est déjà pris (`ss -tlnp | grep 9090`), arrêtez le processus en cause ou adaptez les ports.
- **Réseau** : les images sont téléchargées depuis Docker Hub, `quay.io`, `gcr.io` ; grafana.com et le dépôt `prometheus-community` sont nécessaires pour l'import de dashboards et le chart Helm.
- **Vérifications** : lancez-les à la main avec `bash atelier-01-prometheus-grafana-ubuntu/step1/verify.sh ; echo "code = $?"`.
- **Nettoyage** : `docker rm -f $(docker ps -aq) && docker volume prune -f` ; `helm uninstall kps -n monitoring`.

> ⚠️ **Attention** : ne faites **jamais** ces ateliers sur un serveur ou cluster de production : ils lancent une charge CPU volontaire (`stress-ng`), des conteneurs `--network host` et des installations de charts.

## Rappel du module

[← Retour au module 10](../README.md)
