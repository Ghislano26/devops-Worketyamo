# LocalStack : premiers pas

**Durée : ~20 minutes.** Compétence travaillée : démarrer un **émulateur AWS local**, configurer `awscli` pour lui parler, et créer votre premier **bucket S3**.

Rappel du [cours Fondamentaux du cloud](https://github.com/Ghislano26/devops-Worketyamo/blob/main/14-cloud-aws/cours/01-fondamentaux-cloud.md) : tout, dans AWS, est une **API**. `awscli` ne fait qu'appeler cette API ; **LocalStack** répond à la place d'AWS, sur `http://localhost:4566`.

```text
awscli ──► http://localhost:4566 (LocalStack, dans un conteneur Docker) ──► « bucket » en mémoire
```

Killercoda ne dispose d'aucun compte AWS : **aucune** ressource réelle n'est créée dans ces ateliers.

> ⚠️ **LocalStack est un émulateur, pas AWS.** Il imite l'**API** des services pour apprendre et tester **sans compte, sans facture et sans risque**, mais :
> - **ce n'est pas le vrai AWS** : aucune ressource réelle n'est créée, les **données disparaissent** quand le conteneur s'arrête ;
> - **certaines fonctions avancées ne sont pas supportées** (ou seulement dans l'édition payante) : par exemple l'**application des policies IAM** (voir l'atelier IAM), des services complexes (EKS réel, réseaux VPC réalistes), la durée réelle des règles de cycle de vie, etc. ;
> - **les comportements peuvent différer** du vrai AWS dans les cas limites : **ne validez jamais** la sécurité ou le coût d'une architecture **uniquement** sur un émulateur.
>
> L'image utilisée ici est **épinglée** (`localstack/localstack:3.8`, édition communautaire) : des versions plus récentes peuvent demander un compte LocalStack.

## Avant de commencer

Docker est déjà disponible sur la machine du scénario. Vérifiez-le :

```bash
docker --version
```{{exec}}

> Le premier lancement **télécharge l'image LocalStack** (environ 1 Go) : comptez une à trois minutes selon la connexion.
