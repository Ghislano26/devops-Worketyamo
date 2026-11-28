# Étape 1 : démarrer LocalStack et configurer `awscli`

Vous allez installer l'outil officiel **AWS CLI v2**, démarrer **LocalStack** dans un conteneur et indiquer à `awscli` de s'adresser à lui :

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

Que fait chaque bloc ?

| Commande | Rôle |
|---|---|
| `aws-cli v2` (zip officiel) | Installe `aws` |
| `docker run -d … -p 4566:4566 -e SERVICES=s3,iam,sts` | Lance LocalStack et n'active que les services utiles (démarrage plus rapide) |
| `aws configure set aws_access_key_id test …` | Identifiants **factices** : LocalStack les accepte tous ; en vrai AWS, **jamais** de clé `test` |
| `aws configure set endpoint_url http://localhost:4566` | Redirige **toutes** les commandes vers LocalStack au lieu d'AWS |
| `aws sts get-caller-identity` | « Qui suis-je ? » : LocalStack répond avec un compte fictif `000000000000` |

Inspectez l'état de LocalStack et la configuration :

```bash
docker ps --filter name=localstack
curl -s http://localhost:4566/_localstack/health | head -c 500; echo
cat ~/.aws/config
```{{exec}}

> Si une commande `aws` répond « Could not connect to the endpoint URL » ou « InvalidClientTokenId » : LocalStack n'est pas encore prêt, ou `endpoint_url` n'est pas configuré. Relancez la boucle `until curl …` puis `aws configure get endpoint_url`.

Cliquez sur **Vérifier**.
