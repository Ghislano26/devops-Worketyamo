# Gestion des secrets

## Pourquoi ce cours ?

Mots de passe de bases de données, clés d'API, jetons, certificats : les **secrets** sont les clés du royaume, et ils fuient **partout** (dépôts Git, journaux de CI, variables d'environnement affichées, images de conteneur, captures d'écran). Une fois fuités, ils sont souvent **valables des mois**. Le [cours sur les secrets en GitOps](../../15-gitops-argocd/cours/06-secrets-dans-gitops.md) a traité un angle précis : **comment stocker des secrets dans un flux Git**. Ce cours **élargit** : l'**architecture d'un coffre** (Vault), les **secrets dynamiques à durée de vie courte** (qui rendent la fuite presque inoffensive), les gestionnaires **cloud**, la **rotation**, l'**audit** et le choix d'une stratégie. L'idée directrice : **un secret qui n'existe que quelques minutes et pour un seul usage a peu de valeur pour un attaquant**.

> Prérequis : [Secrets dans GitOps](../../15-gitops-argocd/cours/06-secrets-dans-gitops.md) (Sealed Secrets, SOPS, External Secrets), [Sécurité dans la CI](../../12-cicd/cours/06-securite-dans-la-ci.md) et [IAM AWS](../../14-cloud-aws/cours/02-aws-iam-et-securite.md).

## 1. Les principes

| Principe | Signification |
|---|---|
| **Jamais en clair** dans le code, Git, les images, les journaux | Détection (gitleaks, trufflehog), *push protection*, revue |
| **Moindre privilège** | Chaque application ne lit **que** ses secrets, avec **le minimum de droits** sur la cible (une base : lecture seule si suffisant) |
| **Courte durée de vie** | Préférer des secrets **temporaires** (secondes à heures) aux secrets statiques de longue durée |
| **Identité plutôt que mot de passe** | L'application s'authentifie avec **son identité** (rôle IAM, `ServiceAccount`) ; pas avec un secret de démarrage |
| **Rotation** | Changer régulièrement et **sans interruption** ; prévoir la rotation d'urgence |
| **Audit** | Journaliser **qui** a lu **quel** secret et **quand** |
| **Un secret, un usage** | Pas de mot de passe partagé entre services ou environnements |

> ⚠️ **Attention** : le problème du « **secret zéro** » : pour lire ses secrets, l'application a besoin d'un premier secret (jeton, mot de passe) pour s'authentifier. Ne le résolvez **pas** avec une variable d'environnement statique : utilisez l'**identité de la plateforme** (compte de service Kubernetes, rôle IAM d'instance, OIDC de la CI), qui ne nécessite aucun secret à distribuer.

## 2. HashiCorp Vault

**Vault** (et son fork communautaire **OpenBao**) est un **coffre de secrets** : il stocke, chiffre, distribue et audite les secrets, et peut **en fabriquer à la demande**.

### Architecture

| Élément | Rôle |
|---|---|
| **Serveur Vault** | API HTTP ; **toutes** les données sont **chiffrées** avant d'être écrites |
| **Backend de stockage** | Où vit la donnée chiffrée : **Raft intégré** (recommandé, HA), Consul, base… |
| **Scellement (*seal*)** | Vault démarre **scellé** : la clé de chiffrement est protégée par des **parts de clé** (Shamir) ou par un **auto-unseal** (KMS cloud, HSM) |
| **Méthodes d'authentification** (*auth methods*) | Comment un client prouve son identité : **Kubernetes**, **AWS IAM**, **OIDC/JWT** (CI), AppRole, LDAP, GitHub… |
| **Moteurs de secrets** (*secrets engines*) | Ce que Vault sait faire : **KV** (clé-valeur versionné), **database** (identifiants dynamiques), **AWS**, **PKI** (certificats), **transit** (chiffrement en tant que service), SSH… |
| **Politiques** (*policies*) | Droits **fins** par chemin (`path "secret/data/boutique/*" { capabilities = ["read"] }`) |
| **Jetons et baux** (*leases*) | Tout accès produit un **jeton** et chaque secret dynamique un **bail** à durée limitée, renouvelable ou **révocable** |
| **Audit devices** | Journal **complet** de toutes les requêtes (fichier, syslog, socket) |

```bash
# Secret statique (KV v2)
vault kv put secret/boutique/api cle_api=valeur-a-remplacer
vault kv get -field=cle_api secret/boutique/api

# Politique minimale et rôle Kubernetes
vault policy write boutique - <<'EOF'
path "secret/data/boutique/*"   { capabilities = ["read"] }
path "database/creds/boutique"  { capabilities = ["read"] }
EOF
vault write auth/kubernetes/role/boutique \
  bound_service_account_names=boutique bound_service_account_namespaces=prod \
  policies=boutique ttl=1h
```

## 3. Secrets dynamiques : l'idée forte de Vault

Avec un **secret statique**, le mot de passe de la base est le **même** pour tous, **longtemps**, partagé par plusieurs personnes. Avec un **secret dynamique**, Vault **crée à la demande** un compte **unique**, avec **un bail court** et **supprime** le compte à l'expiration.

```bash
# Configuration du moteur database (une fois, par l'équipe plateforme)
vault secrets enable database
vault write database/config/boutique-pg \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@pg.exemple.org:5432/boutique" \
  allowed_roles="boutique" username="vault_admin" password="$MDP_ADMIN_VAULT"

vault write database/roles/boutique \
  db_name=boutique-pg \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT SELECT,INSERT,UPDATE ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
  default_ttl=1h max_ttl=24h

# Côté application : demander des identifiants
vault read database/creds/boutique
# Key              Value
# lease_id         database/creds/boutique/2f6a...
# lease_duration   1h
# username         v-kubernetes-boutique-8Qx2...
# password         A1a-...
```

```mermaid
flowchart LR
    APP["🟢 Application<br/>(ServiceAccount Kubernetes)"] -->|"1. s'authentifie<br/>(jeton du ServiceAccount)"| VAULT["🏦 Vault<br/>méthode d'auth Kubernetes"]
    VAULT -->|"2. vérifie l'identité<br/>auprès de l'API Kubernetes"| K8S["☸️ API Kubernetes<br/>(TokenReview)"]
    VAULT -->|"3. jeton Vault<br/>limité par la politique"| APP
    APP -->|"4. read database/creds/boutique"| VAULT
    VAULT -->|"5. CREATE ROLE temporaire<br/>(TTL 1 h)"| DB[("🗄️ PostgreSQL")]
    VAULT -->|"6. identifiants + bail (lease)"| APP
    APP -->|"7. connexion avec<br/>les identifiants temporaires"| DB
    VAULT -. "8. à l'expiration du bail :<br/>DROP ROLE automatique" .-> DB
    VAULT -. "journal d'audit<br/>qui, quoi, quand" .-> AUDIT[("📜 Audit device")]
```

| Avantages | Limites |
|---|---|
| Un identifiant **par instance** et **par bail** : une fuite est **bornée** (1 h) et **attribuable** | Complexité : Vault est un système critique à exploiter (HA, sauvegardes, unseal) |
| **Révocation immédiate** (`vault lease revoke -prefix database/creds/boutique`) | L'application doit **gérer le renouvellement** des identifiants (agent Vault, bibliothèque) |
| Plus de mot de passe partagé ni de rotation manuelle | Charge sur la base (création/suppression de comptes) |
| **Audit** complet | Si Vault tombe, les nouvelles demandes échouent : **HA obligatoire** |

> 📌 **À retenir** : la **rotation** d'un secret statique est un **projet** (coordination, redémarrages). Avec des secrets dynamiques, la rotation est **intégrée** : chaque bail est un nouveau secret. C'est la forme la plus aboutie du moindre privilège dans le temps.

### Comment l'application récupère ses secrets

| Méthode | Principe | Quand |
|---|---|---|
| **Vault Agent / injecteur** | Sidecar qui s'authentifie, récupère, **renouvelle** et écrit dans un volume mémoire | Applications **sans modification** |
| **External Secrets Operator** | Crée un `Secret` Kubernetes depuis Vault, rafraîchi régulièrement | Écosystème **GitOps**, compatibilité maximale |
| **CSI Driver** (Secrets Store) | Monte les secrets comme **volume** | Éviter les `Secret` Kubernetes |
| **Appel direct à l'API / SDK** | L'application parle à Vault | Contrôle fin, secrets dynamiques gérés par le code |

## 4. Secrets Kubernetes et External Secrets

Un `Secret` Kubernetes est **encodé en base64, pas chiffré** ; il est lisible par quiconque a le droit `get secrets` dans le namespace, et stocké en clair dans **etcd** sauf chiffrement au repos activé.

| Outil | Rôle | Voir |
|---|---|---|
| **External Secrets Operator** | Synchronise un coffre externe (Vault, AWS Secrets Manager, GCP, Azure) vers des `Secret` Kubernetes via `ExternalSecret` | [Cours GitOps 6](../../15-gitops-argocd/cours/06-secrets-dans-gitops.md) |
| **Sealed Secrets** | Chiffre le secret **dans Git** ; contrôleur dans le cluster | idem |
| **SOPS + age / KMS** | Chiffre les **valeurs** d'un fichier YAML | idem |
| **Chiffrement d'etcd** (`EncryptionConfiguration`, KMS) | Protège les `Secret` **au repos** | Obligatoire en production |
| **RBAC strict** | Limiter `get/list/watch secrets` | `list secrets` équivaut à **lire tous les secrets** |

## 5. Gestionnaires de secrets cloud

| Service | Particularités |
|---|---|
| **AWS Secrets Manager** | Stockage chiffré (KMS), **rotation automatique** via fonction Lambda (modèles pour RDS), versions (`AWSCURRENT`, `AWSPREVIOUS`), accès par **IAM**, journal **CloudTrail** ; facturé par secret et par appel |
| **AWS SSM Parameter Store** | Paramètres (dont `SecureString`) ; moins cher, pas de rotation native |
| **GCP Secret Manager / Azure Key Vault** | Équivalents, intégrés à l'IAM de leur cloud |

```bash
aws secretsmanager create-secret --name boutique/prod/bdd \
  --secret-string '{"username":"app","password":"à-remplacer"}'
aws secretsmanager get-secret-value --secret-id boutique/prod/bdd --query SecretString --output text
aws secretsmanager rotate-secret --secret-id boutique/prod/bdd \
  --rotation-lambda-arn arn:aws:lambda:eu-west-3:123456789012:function:rotation-rds \
  --rotation-rules AutomaticallyAfterDays=30
```

Sur AWS, l'application récupère le secret **avec son rôle IAM** (rôle d'instance, **IRSA**/**Pod Identity** sur EKS : [cours calcul](../../14-cloud-aws/cours/03-aws-compute-ec2-et-eks.md)) : **aucun secret de départ**, la politique IAM autorise `secretsmanager:GetSecretValue` sur **cet** ARN uniquement.

| | **Vault** | **Gestionnaire cloud** |
|---|---|---|
| **Portabilité** | Multi-cloud, sur site | Lié à un cloud |
| **Secrets dynamiques** | **Très riches** (bases, cloud, PKI, SSH) | Limités (rotation, pas de génération à la demande) |
| **Exploitation** | **À exploiter** (HA, scellement) ou HCP Vault | **Managé** |
| **Intégration IAM** | Via méthodes d'auth | **Native** |
| **Coût** | Licence / hébergement + exploitation | Au secret et à l'appel |

## 6. Rotation et révocation

| Cas | Ce qu'il faut faire |
|---|---|
| **Rotation planifiée** | Fréquence selon sensibilité (30 à 90 jours pour du statique) ; **double secret** pendant la transition (l'ancien et le nouveau valides le temps du déploiement) |
| **Secrets dynamiques** | Rotation **automatique** à chaque bail |
| **Fuite avérée** | **Révoquer immédiatement**, remplacer, redéployer, **enquêter** (journaux d'audit : qui l'a utilisé depuis ?), corriger la cause |
| **Départ d'une personne** | Révoquer ses accès ; les secrets qu'elle a **connus** sont à renouveler |
| **Certificats** | Automatiser (cert-manager, ACME, moteur **PKI** de Vault) avec des durées courtes |

> 💡 **Conseil** : **préparez** la rotation **avant** d'en avoir besoin. Une application qui ne sait pas **relire** son secret sans redémarrer, ou un secret codé en dur à 12 endroits, transformera la rotation d'urgence en **incident majeur**. Testez-la en conditions réelles (« fire drill »).

## 7. Audit et détection

- **Journaux d'audit** du coffre (Vault audit devices, CloudTrail) : **qui, quoi, quand, depuis où** ; à envoyer vers un système **hors de portée** des administrateurs du coffre.
- **Alertes** sur les comportements anormaux : lecture massive, accès hors horaires, échecs d'authentification répétés, requêtes depuis une nouvelle origine.
- **Détection de secrets** dans le code et les images : `gitleaks` (pré-commit et CI), `trufflehog`, *secret scanning* du forge, `trivy` (option `--scanners secret`).
- **Revue périodique des accès** (qui peut lire quoi), et **inventaire** des secrets avec propriétaire.

## 8. Choisir

| Situation | Approche recommandée |
|---|---|
| Petite équipe, un cluster, démarrage | **Sealed Secrets** ou **SOPS** ; chiffrement d'etcd ; gitleaks |
| Équipe sur **AWS**, applications sur EKS/EC2 | **AWS Secrets Manager** + IAM (IRSA) + **External Secrets Operator** |
| **Multi-cloud**, besoin de **secrets dynamiques**, PKI, conformité | **Vault / OpenBao** (+ ESO ou agent) |
| Secrets de **CI** | **OIDC** vers le cloud (aucun secret durable) plutôt que des variables de CI |
| Certificats | **cert-manager** + ACME / PKI Vault |

## Résumé

- Principes : **jamais en clair**, **moindre privilège**, **courte durée**, **identité plutôt que mot de passe**, **rotation**, **audit** ; attention au **« secret zéro »**.
- **Vault** : stockage chiffré (Raft), **scellement**, **méthodes d'auth** (Kubernetes, AWS, OIDC), **moteurs** (KV, database, PKI, transit), **politiques**, **baux**, **audit**.
- **Secrets dynamiques** : comptes **uniques et temporaires**, révoqués à l'expiration ; fuite **bornée et attribuable**.
- `Secret` Kubernetes = base64 : **chiffrer etcd**, RBAC strict, **ESO / CSI / agent** pour récupérer depuis un coffre.
- **AWS Secrets Manager** : IAM, KMS, **rotation par Lambda**, CloudTrail ; **Vault** pour multi-cloud et dynamique.
- **Rotation** préparée et testée ; **réponse à fuite** : révoquer, remplacer, enquêter ; **détection** (gitleaks, trufflehog) et **audit** continus.

## Pour aller plus loin

- Vault : <https://developer.hashicorp.com/vault/docs> ; OpenBao : <https://openbao.org/> ; External Secrets : <https://external-secrets.io/> ; AWS Secrets Manager : <https://docs.aws.amazon.com/secretsmanager/>.
- Outils : `gitleaks`, `trufflehog`, `cert-manager`, `vault-k8s`, Secrets Store CSI Driver.
- Cours suivant : [Durcissement et CIS Benchmarks](06-hardening-et-cis-benchmarks.md).
