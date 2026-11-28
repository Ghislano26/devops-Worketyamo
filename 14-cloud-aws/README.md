# Module 14 — Cloud AWS

## Pourquoi ce module ?

Vous savez construire ([Docker](../08-docker-approfondi/README.md)), orchestrer ([Kubernetes](../09-kubernetes-approfondi/README.md)), livrer ([CI/CD](../12-cicd/README.md)) et décrire une infrastructure par le code ([IaC](../13-iac/README.md)). Reste à savoir **sur quoi tout cela tourne** : pour la majorité des entreprises, un **fournisseur de cloud public**, et en tête **AWS**. Ce module donne les **fondamentaux** nécessaires pour y travailler sans danger : comprendre le modèle (IaaS, régions, responsabilité partagée), **sécuriser** les accès (IAM), choisir le **calcul**, le **réseau** et le **stockage**, et **maîtriser la facture**.

> 🗺️ **Place dans le parcours.** Ce module porte le **numéro 14** et se lit **après l'IaC (13)**, **avant le Monitoring (10) et le SRE (11)** : **on provisionne l'infrastructure cloud, on la déploie, on l'observe**. La numérotation des dossiers est gelée ; l'ordre pédagogique est expliqué dans le [README principal](../README.md).

## Prérequis

| Module | Ce qui est mobilisé |
|---|---|
| [04 Linux expert](../04-linux-expert/README.md) | Processus, services, SSH : ce qui tourne dans une instance |
| [06 Réseaux](../06-reseaux-devops/README.md) | CIDR, routage, NAT, pare-feu : le VPC les implémente |
| [08 Docker](../08-docker-approfondi/README.md) | Conteneurs : ECS, EKS, Fargate ; **les ateliers lancent LocalStack avec Docker** |
| [09 Kubernetes](../09-kubernetes-approfondi/README.md) | Concepts utiles pour EKS |
| [13 IaC](../13-iac/README.md) | Décrire les ressources AWS avec Terraform |

## Cours

| # | Cours | Niveau | Ce que vous maîtriserez |
|---|---|---|---|
| 1 | [Fondamentaux du cloud](cours/01-fondamentaux-cloud.md) | ⭐⭐ | IaaS/PaaS/SaaS, régions et AZ, responsabilité partagée, panorama des services, pourquoi AWS domine, cloud vs on-premise |
| 2 | [AWS IAM et sécurité](cours/02-aws-iam-et-securite.md) | ⭐⭐⭐ | Utilisateurs, groupes, rôles, policies JSON, moindre privilège, MFA, STS et `AssumeRole`, bonnes pratiques |
| 3 | [Le calcul : EC2, EKS, ECS, Lambda](cours/03-aws-compute-ec2-et-eks.md) | ⭐⭐⭐⭐ | Types d'instances, AMI, security groups, user data, Auto Scaling, EKS, ECS/Fargate, Lambda, choix du bon service |
| 4 | [Le réseau : VPC](cours/04-aws-reseau-vpc.md) | ⭐⭐⭐⭐ | Sous-réseaux publics/privés, IGW, NAT, tables de routage, security groups vs NACL, peering, Transit Gateway, PrivateLink |
| 5 | [Le stockage : S3, EBS, EFS](cours/05-aws-stockage-s3-ebs-efs.md) | ⭐⭐⭐ | Classes S3, cycle de vie, versioning, chiffrement, types EBS, instantanés, EFS, comparaison |
| 6 | [Coûts et introduction au FinOps](cours/06-aws-couts-finops-intro.md) | ⭐⭐⭐ | Modèles de tarification, Cost Explorer, budgets, étiquettes, dimensionnement, Free Tier, stratégie de réduction |

## Ateliers interactifs (Killercoda, avec LocalStack)

Killercoda ne peut pas créer de **vraies** ressources AWS (pas de compte, pas de facturation). Les ateliers utilisent donc **LocalStack**, un **émulateur** d'API AWS qui tourne dans un conteneur Docker, avec le vrai `awscli`.

| Atelier | Backend | Niveau | Associé aux cours |
|---|---|---|---|
| [Atelier 01 — LocalStack, premiers pas](ateliers-killercoda/atelier-01-localstack-premiers-pas/intro.md) (2 étapes) | `ubuntu` | ⭐⭐ | 1, 5 |
| [Atelier 02 — S3 avec awscli](ateliers-killercoda/atelier-02-s3-avec-awscli/intro.md) (3 étapes) | `ubuntu` | ⭐⭐⭐ | 5, 6 |
| [Atelier 03 — IAM et policies](ateliers-killercoda/atelier-03-iam-policies/intro.md) (2 étapes) | `ubuntu` | ⭐⭐⭐ | 2 |

Procédure de publication : [`ateliers-killercoda/README.md`](ateliers-killercoda/README.md) et [`../KILLERCODA.md`](../KILLERCODA.md).

> ⚠️ **LocalStack n'est pas AWS.** C'est un émulateur : aucune ressource réelle n'est créée, les données sont **éphémères**, et certaines fonctions avancées **ne sont pas supportées** (par exemple, l'édition communautaire **n'applique pas** les policies IAM : l'atelier 3 le dit explicitement et fournit un évaluateur local). **Ne validez jamais la sécurité ou le coût d'une architecture uniquement sur un émulateur.**

## Parcours recommandé

```text
Cours 01 → Atelier 01 (LocalStack) → Cours 02 → Atelier 03 (IAM)
        → Cours 03 → Cours 04 → Cours 05 → Atelier 02 (S3)
        → Cours 06
```

## Ce que vous saurez faire à la fin

- Situer **IaaS, PaaS, SaaS**, expliquer **régions, AZ** et la **responsabilité partagée**.
- Écrire une **policy IAM de moindre privilège**, comprendre l'**évaluation** (refus implicite/explicite) et utiliser des **rôles** plutôt que des clés.
- **Choisir** entre EC2, ECS, EKS, Fargate et Lambda selon le besoin.
- Concevoir un **VPC trois tiers** (public / privé / isolé) et expliquer **security group vs NACL**.
- Choisir **S3, EBS ou EFS**, activer **versioning** et **cycle de vie**.
- **Estimer et réduire** une facture : modèles de tarification, étiquettes, dimensionnement, budgets.

## Et après ?

Un module **FinOps** dédié est prévu pour approfondir le dernier cours. Pour pratiquer sur un vrai compte : activez un **budget et des alertes** d'abord, reprenez les exemples avec **Terraform** ([module 13](../13-iac/README.md)) et **détruisez** tout après chaque essai.

## Navigation

- [← Module 13 — Infrastructure as Code](../13-iac/README.md)
- [→ Module 15 — GitOps avec Argo CD](../15-gitops-argocd/README.md) (étape suivante du parcours)
- [← README principal](../README.md)
