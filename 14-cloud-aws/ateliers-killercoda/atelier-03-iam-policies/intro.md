# IAM : utilisateurs, policies et moindre privilège

**Durée : ~30 minutes.** Compétence travaillée : créer un **utilisateur IAM**, écrire une **policy JSON de moindre privilège**, la **tester**, puis la **corriger**.

Rappel du [cours IAM](https://github.com/Ghislano26/devops-Worketyamo/blob/main/14-cloud-aws/cours/02-aws-iam-et-securite.md) :

```text
Par défaut : tout est refusé  →  un Deny explicite l'emporte  →  sinon il faut un Allow
```

> 🔑 **Limite importante à connaître** : l'édition **communautaire** de LocalStack **crée bien** les utilisateurs, clés et policies IAM (vous les manipulez et les vérifiez avec les vraies commandes `aws iam`), mais **n'applique pas** les policies aux requêtes : un utilisateur « en lecture seule » **pourra encore écrire** dans LocalStack, alors qu'il serait refusé (`AccessDenied`) sur le vrai AWS.
>
> Pour **tester malgré tout** vos policies, cet atelier vous fait écrire un petit **évaluateur local** (`evaluer-policy.py`) qui applique la **même logique** qu'AWS (refus par défaut, `Deny` explicite prioritaire, jokers). C'est un outil pédagogique : sur un vrai compte, utilisez l'**IAM Policy Simulator** ou `aws iam simulate-principal-policy`.

> ⚠️ **LocalStack est un émulateur, pas AWS.** Il imite l'**API** des services pour apprendre et tester **sans compte, sans facture et sans risque**, mais :
> - **ce n'est pas le vrai AWS** : aucune ressource réelle n'est créée, les **données disparaissent** quand le conteneur s'arrête ;
> - **certaines fonctions avancées ne sont pas supportées** (ou seulement dans l'édition payante) : par exemple l'**application des policies IAM** (voir l'atelier IAM), des services complexes (EKS réel, réseaux VPC réalistes), la durée réelle des règles de cycle de vie, etc. ;
> - **les comportements peuvent différer** du vrai AWS dans les cas limites : **ne validez jamais** la sécurité ou le coût d'une architecture **uniquement** sur un émulateur.
>
> L'image utilisée ici est **épinglée** (`localstack/localstack:3.8`, édition communautaire) : des versions plus récentes peuvent demander un compte LocalStack.

## Mise en place

Installez `awscli`, démarrez LocalStack et attendez qu'il soit prêt (2 à 4 minutes, dont le téléchargement de l'image).

```bash
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq && apt-get install -y -qq unzip curl >/dev/null
curl -fsSL -o /tmp/awscliv2.zip https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
unzip -oq /tmp/awscliv2.zip -d /tmp
/tmp/aws/install --update
aws --version
docker run -d --name localstack -p 4566:4566 -e SERVICES=s3,iam,sts localstack/localstack:3.8
aws configure set aws_access_key_id test
aws configure set aws_secret_access_key test
aws configure set region eu-west-3
aws configure set endpoint_url http://localhost:4566
aws configure set cli_pager ""
until curl -fs http://localhost:4566/_localstack/health >/dev/null; do echo "LocalStack démarre…"; sleep 3; done
aws sts get-caller-identity
```{{exec}}
