# Ateliers Killercoda — Cloud AWS (LocalStack)

Trois scénarios qui s'exécutent sur **[Killercoda](https://killercoda.com/)** : un serveur Ubuntu dans le navigateur. Killercoda **ne peut pas créer de vraies ressources AWS** ; les scénarios utilisent donc **LocalStack**, un **émulateur d'API AWS** lancé avec Docker, et le vrai **`awscli` v2**, installé par l'introduction de chaque scénario.

> ⚠️ **LocalStack est un émulateur, pas AWS.** Aucune ressource réelle n'est créée ; les données disparaissent à l'arrêt du conteneur ; certaines fonctions avancées ne sont pas supportées ou diffèrent du vrai AWS. En particulier, l'édition **communautaire** **n'applique pas** les policies IAM (l'atelier 3 le traite honnêtement) et ne **déclenche pas** l'expiration des règles de cycle de vie (l'atelier 2 vérifie la configuration, pas son exécution).

| Scénario | Backend | Durée | Niveau | Notions | Cours associés |
|---|---|---|---|---|---|
| [`atelier-01-localstack-premiers-pas`](atelier-01-localstack-premiers-pas/) | `ubuntu` | ~20 min | ⭐⭐ | Docker + LocalStack, `awscli`, `endpoint_url`, bucket S3, `s3` vs `s3api` | [1](../cours/01-fondamentaux-cloud.md), [5](../cours/05-aws-stockage-s3-ebs-efs.md) |
| [`atelier-02-s3-avec-awscli`](atelier-02-s3-avec-awscli/) | `ubuntu` | ~30 min | ⭐⭐⭐ | Versioning, restauration d'une version, marqueur de suppression, règles de cycle de vie | [5](../cours/05-aws-stockage-s3-ebs-efs.md), [6](../cours/06-aws-couts-finops-intro.md) |
| [`atelier-03-iam-policies`](atelier-03-iam-policies/) | `ubuntu` | ~30 min | ⭐⭐⭐ | Utilisateur IAM, policy JSON de moindre privilège, évaluateur local, nouvelle version de policy | [2](../cours/02-aws-iam-et-securite.md) |

**Lisez le cours associé avant chaque atelier.** Les cours 3 (calcul) et 4 (VPC) ne sont pas pratiqués ici : EC2, EKS et un VPC réaliste ne sont pas, ou mal, émulés par l'édition communautaire ; ils se pratiquent sur un vrai compte (avec budget et alertes) ou avec Terraform ([module 13](../../13-iac/README.md)).

## Ce que fait chaque scénario sur la machine

| Atelier | Installe / lance | Crée | Vérification (`verify.sh`) |
|---|---|---|---|
| 1 | `awscli` v2 (zip officiel), conteneur `localstack/localstack:3.8` (services `s3,iam,sts`) | Bucket `mon-premier-bucket`, objet `bonjour.txt` | Santé de LocalStack, `endpoint_url`, `sts get-caller-identity`, **bucket et contenu de l'objet lus via `awscli`** |
| 2 | Idem | Bucket `archives-worketyamo`, 3 versions de `rapport.txt`, `lifecycle.json` | **Versioning actif**, nombre de versions, version courante, absence de marqueur de suppression, **règles de cycle de vie relues dans LocalStack** |
| 3 | Idem | Utilisateur `lecteur`, policy `LectureDonnees` (v1 puis v2), `~/iam-lab/evaluer-policy.py` | **Utilisateur, policy attachée et clés vérifiés dans LocalStack** ; la **version par défaut de la policy** est relue et évaluée (lecture oui ; écriture hors `uploads/` et suppression non) |

Les vérifications **interrogent l'état réel de LocalStack** via `awscli`, pas seulement la présence de fichiers.

## Prérequis réseau et ressources

| Téléchargement | Source | Taille indicative |
|---|---|---|
| Image `localstack/localstack:3.8` | Docker Hub (`docker run`) | **~1 Go** : une à trois minutes au premier lancement |
| `awscli` v2 | `awscli.amazonaws.com` | ~60 Mo |
| `unzip`, `curl` | Dépôts Ubuntu (`apt`) | quelques Mo |

Chaque scénario est **indépendant** : il installe et démarre son propre LocalStack (l'état n'est pas partagé d'un atelier à l'autre). L'image est **épinglée** : une version plus récente de LocalStack peut exiger un compte ou un jeton.

## Publier sur Killercoda

Procédure complète (dépôt GitHub, `structure.json`, mises à jour, tests) dans [**`KILLERCODA.md`**](../../KILLERCODA.md). Contrôle local avant de pousser :

```bash
python3 scripts/check-killercoda.py
```

> ⚠️ **Attention** : sur un **vrai** compte AWS, ne réutilisez jamais les identifiants `test` de ces ateliers, et lisez les conditions du Free Tier avant de créer quoi que ce soit.

[← Retour au module 14](../README.md)
