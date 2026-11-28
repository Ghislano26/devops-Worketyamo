# Bravo !

Vous avez écrit et testé votre première politique d'admission :

| Notion | Ce que vous avez vu |
|---|---|
| **Kyverno** | Contrôleurs d'admission, de fond, de rapports, installés par Helm |
| **ClusterPolicy** | Règles `validate` avec `pattern` YAML, sans apprendre un nouveau langage |
| **Enforce** | Un pod `:latest` ou sans tag est **refusé** avec un message clair |
| **Audit** | Le pod est créé mais la violation est **consignée** (PolicyReport) |
| **dry-run serveur** | Tester une politique sans rien créer, utilisable en CI |

## Défi bonus

1. Ajoutez une règle qui **exige un label `equipe`** sur tous les Deployments (`validate.pattern.metadata.labels.equipe: "?*"`).
2. Écrivez une politique qui **interdit les conteneurs privilégiés** (`securityContext.privileged: "!true"`) et testez-la.
3. Ajoutez une règle de **mutation** qui ajoute `runAsNonRoot: true` si absent ([cours 4](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/04-policy-as-code-kubernetes.md)).
4. Installez la CLI `kyverno` et écrivez un `kyverno-test.yaml` avec un cas `pass` et un cas `fail`.
5. Excluez un namespace précis avec `exclude` et vérifiez qu'un pod `:latest` y passe.

## Pour aller plus loin

- [Policy as code pour Kubernetes](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/04-policy-as-code-kubernetes.md) · [Signature et provenance](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/03-signature-et-provenance.md) (`verifyImages`) · [Durcissement et CIS](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/06-hardening-et-cis-benchmarks.md) (Pod Security Standards).
- Retour au [module 16](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/README.md).
