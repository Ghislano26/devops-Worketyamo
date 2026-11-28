# Signature d'image avec cosign

**Durée : ~25 minutes.** Compétence travaillée : **signer** une image avec **cosign**, **vérifier** sa signature, constater qu'une image **non signée** ou **modifiée** échoue à la vérification, et **simuler un contrôleur d'admission** qui refuse ce qui n'est pas signé.

Rappel du [cours Signature et provenance](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/03-signature-et-provenance.md) :

```text
Registre local (localhost:5000)
   demo/app:1.0          ← signée avec NOTRE clé privée  → vérification OK  → ADMISE
   demo/non-signee:1.0   ← aucune signature              → vérification KO  → REFUSÉE
```

> ⚠️ **Mode avec clé, sans journal de transparence.** Pour fonctionner **sans Internet public ni compte d'identité**, cet atelier signe **avec une paire de clés locale** et **sans Rekor** (`--tlog-upload=false`, `--insecure-ignore-tlog=true`). En production, on préfère souvent le mode **keyless** (Fulcio + Rekor, identité OIDC de la CI) ou des clés dans un **KMS** ; ce mode n'est **pas** pratiqué ici car il exige un fournisseur d'identité interactif. L'admission est **simulée par un script**, pas par un vrai contrôleur Kubernetes (voir l'[atelier 3](https://github.com/Ghislano26/devops-Worketyamo/tree/main/16-devsecops/ateliers-killercoda/atelier-03-kyverno-policies) pour Kyverno et le [cours 3](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/03-signature-et-provenance.md) pour `verifyImages`).

> 🌐 **Réseau** : le scénario télécharge `cosign` (releases GitHub, ~100 Mo) et des images (`registry:2`, `alpine`, `busybox`) depuis Docker Hub.

## Mise en place

```bash
apt-get update -qq && apt-get install -y -qq jq >/dev/null
curl -sSL -o /usr/local/bin/cosign https://github.com/sigstore/cosign/releases/download/v2.4.1/cosign-linux-amd64
chmod +x /usr/local/bin/cosign
cosign version | head -n 8
docker --version
```{{exec}}
