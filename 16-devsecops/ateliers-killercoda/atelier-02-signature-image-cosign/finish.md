# Bravo !

Vous avez pratiqué la boucle **signer → publier → vérifier → admettre** :

| Notion | Ce que vous avez vu |
|---|---|
| **Paire de clés** | `cosign generate-keypair` : privée à protéger, publique à distribuer |
| **Signature** | Du **digest**, stockée dans le registre à côté de l'image |
| **Vérification** | `cosign verify --key` : réussit pour l'image signée, échoue sinon |
| **Tag réécrit** | Détecté : une signature ne vaut que pour **un** digest |
| **Admission** | Le principe d'un contrôleur qui **refuse** ce qui n'est pas signé |

## Défi bonus

1. Générez une **seconde paire de clés** et vérifiez l'image avec la **mauvaise** clé publique : que se passe-t-il ?
2. **Attestez** une SBOM : `cosign attest --key cosign.key --tlog-upload=false --type cyclonedx --predicate sbom.cdx.json IMAGE` puis `cosign verify-attestation --key cosign.pub --insecure-ignore-tlog=true --type cyclonedx IMAGE` ([atelier 1](https://github.com/Ghislano26/devops-Worketyamo/tree/main/16-devsecops/ateliers-killercoda/atelier-01-sbom-et-scan-vulnerabilites) pour produire la SBOM).
3. Affichez la structure des artefacts liés : `cosign tree localhost:5000/demo/app:1.0`.
4. Lisez le [cours 3](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/03-signature-et-provenance.md) et écrivez, sur papier, la politique **Kyverno `verifyImages`** qui ferait ce que fait `admission.sh`.

## Pour aller plus loin

- [Signature et provenance](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/03-signature-et-provenance.md) · [Policy as code Kubernetes](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/04-policy-as-code-kubernetes.md).
- Suite : [atelier 3 — politiques Kyverno](https://github.com/Ghislano26/devops-Worketyamo/tree/main/16-devsecops/ateliers-killercoda/atelier-03-kyverno-policies).
