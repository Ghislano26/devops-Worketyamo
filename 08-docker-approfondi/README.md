# Module 08 — Docker approfondi

## Pourquoi ce module ?

Le [module 05](../05-devops-outils/cours/02-docker-fondamentaux.md) vous a fait lancer vos premiers conteneurs. Ici, on passe à la **maîtrise** :
comprendre l'architecture, maîtriser les images et le cache, écrire des Dockerfile de production, concevoir réseau et stockage,
orchestrer plusieurs conteneurs avec Compose et **sécuriser** l'ensemble. Ce module prépare directement le [module 09 — Kubernetes](../09-kubernetes-approfondi/README.md).

> Ce module **ne répète pas** les bases : il s'appuie sur les [namespaces et cgroups du module 04](../04-linux-expert/cours/02-conteneurs-namespaces.md) et sur les [réseaux du module 06](../06-reseaux-devops/README.md) (DNS, NAT, ports).

## Prérequis

- Linux en ligne de commande (modules 01-03) ; **namespaces / cgroups** (module 04).
- **DNS, ports, routage et NAT** (module 06).
- Docker de base (module 05) ; une VM Ubuntu avec Docker installé, **ou** un compte [Killercoda](https://killercoda.com/) pour les ateliers interactifs.

## Cours

| # | Cours | Ce que vous maîtriserez |
|---|---|---|
| 1 | [Architecture de Docker](cours/01-architecture-docker.md) | `dockerd`, `containerd`, `runc`, cycle de vie, API et socket, image vs conteneur |
| 2 | [Images et couches](cours/02-images-et-couches.md) | OverlayFS, cache de build, tags vs digests, tailles (`slim`, `alpine`, distroless, `scratch`) |
| 3 | [Dockerfile avancé](cours/03-dockerfile-avance.md) | Multi-stage, BuildKit (cache, secrets), `ENTRYPOINT`/`CMD`, PID 1, `HEALTHCHECK`, non-root |
| 4 | [Réseau et stockage](cours/04-reseau-et-stockage-docker.md) | Drivers, DNS interne, `-p` et DNAT, volumes, bind mounts, UID/GID, sauvegarde |
| 5 | [Docker Compose](cours/05-docker-compose.md) | Structure, `depends_on` + santé, profils, `x-*`, `.env`, surcharges, limites |
| 6 | [Sécurité et bonnes pratiques](cours/06-securite-et-bonnes-pratiques.md) | Capabilities, seccomp, AppArmor, rootless, secrets, Trivy, cosign, CIS |

## Ateliers interactifs (Killercoda)

| Atelier | Associé aux cours |
|---|---|
| [Atelier 01 — Premiers pas](ateliers-killercoda/atelier-01-premiers-pas/intro.md) | 1, 4 |
| [Atelier 02 — Dockerfile multi-stage](ateliers-killercoda/atelier-02-dockerfile-multistage/intro.md) | 2, 3 |
| [Atelier 03 — Compose et réseau](ateliers-killercoda/atelier-03-compose-reseau/intro.md) | 4, 5 |

### Lancer les ateliers sur Killercoda

1. Lisez le cours associé.
2. Ouvrez le scénario sur Killercoda (après avoir lié ce dépôt à votre profil : voir [`ateliers-killercoda/README.md`](ateliers-killercoda/README.md)). L'environnement est une machine **`ubuntu`** avec Docker préinstallé.
3. Suivez les étapes ; cliquez sur **Vérifier** à la fin de chacune.

Les commandes fonctionnent aussi sur votre propre VM Ubuntu ; les scripts `verify.sh` se lancent alors à la main.

## Parcours recommandé

```text
Cours 01 → Cours 02 → Atelier 01 → Cours 03 → Atelier 02 → Cours 04 → Cours 05 → Atelier 03 → Cours 06
```

## Pour la suite

Compose s'arrête à une machine. Le [module 09 — Kubernetes approfondi](../09-kubernetes-approfondi/README.md) vous fait passer à l'échelle d'un cluster :
Deployments, Services, stockage persistant, configuration, ordonnancement et sécurité.

> ⚠️ **Attention** : les commandes de ce module créent et suppriment des conteneurs, réseaux et volumes. Sur votre propre machine, prenez un **snapshot** de la VM et évitez `docker system prune -a --volumes` si vous avez des données à conserver.

## Navigation

- [← Module 07 — Git branching interactif](../07-git-branching-interactif/README.md)
- [→ Module 09 — Kubernetes approfondi](../09-kubernetes-approfondi/README.md)
- [← README principal](../README.md)
