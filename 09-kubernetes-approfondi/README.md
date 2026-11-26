# Module 09 — Kubernetes approfondi

## Pourquoi ce module ?

Docker et Compose font tourner des conteneurs sur **une machine**. Kubernetes les orchestre sur **un cluster** : placement, auto-réparation, mises à jour sans coupure,
découverte de services, stockage, configuration, sécurité. C'est la plateforme standard des applications conteneurisées, et une compétence centrale du métier DevOps.
Ce module (niveau **CKA/CKAD**) explique **comment ça fonctionne** avant de vous faire pratiquer.

> Il **ne répète pas** les bases : il mobilise le [module 04](../04-linux-expert/cours/02-conteneurs-namespaces.md) (namespaces, cgroups), le [module 06](../06-reseaux-devops/README.md) (DNS, NAT, TLS, diagnostic) et surtout le **[module 08 — Docker approfondi](../08-docker-approfondi/README.md)** (images, Dockerfile, volumes, Compose, sécurité des conteneurs).

## Prérequis

- **Docker approfondi** (module 08) : images et couches, Dockerfile, réseau et stockage, sécurité.
- **Réseaux DevOps** (module 06) : DNS, ports, routage/NAT, diagnostic ; Linux (modules 01-04).
- Aucun cluster à installer : les ateliers tournent sur **Killercoda**. Pour pratiquer en local : **kind**, **minikube** ou **k3s**.

## Cours

| # | Cours | Ce que vous maîtriserez | S'appuie sur |
|---|---|---|---|
| 1 | [Architecture et composants](cours/01-architecture-et-composants.md) | Control plane, kubelet, etcd, flux d'un `kubectl apply`, namespaces, containerd (pas dockerd) | [Docker 01](../08-docker-approfondi/cours/01-architecture-docker.md) |
| 2 | [Pods et workloads](cours/02-pods-et-workloads.md) | Pod, sondes, init/sidecar, Deployment et rollout, StatefulSet, DaemonSet, Job, CronJob | [Docker 03](../08-docker-approfondi/cours/03-dockerfile-avance.md), [Compose](../08-docker-approfondi/cours/05-docker-compose.md) |
| 3 | [Services et réseau](cours/03-services-et-reseau-kubernetes.md) | Modèle réseau plat, Services, CoreDNS, Ingress, aperçu NetworkPolicies | [Docker 04](../08-docker-approfondi/cours/04-reseau-et-stockage-docker.md), [module 06](../06-reseaux-devops/README.md) |
| 4 | [Stockage et persistance](cours/04-stockage-persistance.md) | emptyDir, PV/PVC, StorageClass, modes d'accès, `volumeClaimTemplates` | [Docker 04](../08-docker-approfondi/cours/04-reseau-et-stockage-docker.md) |
| 5 | [Configuration et secrets](cours/05-configuration-et-secrets.md) | ConfigMap, Secret, env vs volumes, immutabilité, Sealed Secrets, ESO, Vault | [Docker 06](../08-docker-approfondi/cours/06-securite-et-bonnes-pratiques.md) |
| 6 | [Scheduling et ressources](cours/06-scheduling-et-ressources.md) | requests/limits, QoS, taints, affinités, topology spread, priorités, HPA/VPA | [cgroups (module 04)](../04-linux-expert/cours/02-conteneurs-namespaces.md) |
| 7 | [Sécurité : RBAC et NetworkPolicies](cours/07-securite-rbac-et-networkpolicies.md) | RBAC, ServiceAccounts, Pod Security Standards, `securityContext`, default-deny | [Docker 06](../08-docker-approfondi/cours/06-securite-et-bonnes-pratiques.md) |

## Ateliers interactifs (Killercoda)

| Atelier | Associé aux cours |
|---|---|
| [Atelier 01 — Premier Pod et Deployment](ateliers-killercoda/atelier-01-premier-pod-et-deployment/intro.md) (3 étapes) | 1, 2 |
| [Atelier 02 — Service et NodePort](ateliers-killercoda/atelier-02-service-et-nodeport/intro.md) (2 étapes) | 3 |
| [Atelier 03 — ConfigMap, Secret et RBAC](ateliers-killercoda/atelier-03-configmap-secret-et-rbac/intro.md) (2 étapes) | 5, 7 |

### Lancer les ateliers sur Killercoda

1. Lisez le cours associé.
2. Ouvrez le scénario sur Killercoda (après avoir lié ce dépôt à votre profil : voir [`ateliers-killercoda/README.md`](ateliers-killercoda/README.md)). L'environnement est un cluster **`kubernetes-kubeadm-1node`** prêt à l'emploi.
3. Attendez que `kubectl get nodes` affiche `Ready`, suivez les étapes, puis cliquez sur **Vérifier**.

## Parcours recommandé

```text
Cours 01 → Cours 02 → Atelier 01 → Cours 03 → Atelier 02 → Cours 04 → Cours 05 → Cours 06 → Cours 07 → Atelier 03
```

## Aide-mémoire minimal

```bash
kubectl get nodes,pods,svc,deploy -A          # vue d'ensemble
kubectl describe pod <nom>                    # chronologie (Events)
kubectl logs <pod> [-c conteneur] --previous  # journaux
kubectl exec -it <pod> -- sh
kubectl apply -f fichier.yaml · kubectl diff -f fichier.yaml
kubectl rollout status|history|undo deployment/<nom>
kubectl auth can-i <verbe> <ressource> --as=<sujet> -n <ns>
kubectl explain <ressource>.spec               # documentation intégrée
```

> 💡 **Conseil** : visez la certification **CKAD** (développeur) ou **CKA** (administrateur) : l'examen se passe **dans un terminal**, avec accès à la documentation officielle. La pratique de `kubectl` et de `explain` est décisive.

## Pour aller plus loin

Helm et Kustomize, GitOps (Argo CD, Flux), observabilité (Prometheus, Grafana : voir le [module 04](../04-linux-expert/cours/03-observabilite-logs.md)), service mesh, opérateurs et CRD, sécurité (CKS), Kubernetes managé (EKS, GKE, AKS).

## Navigation

- [← Module 08 — Docker approfondi](../08-docker-approfondi/README.md)
- [← README principal](../README.md)
