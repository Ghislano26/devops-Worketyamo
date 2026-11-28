# Étape 1 : registre local, clés et signature

## A. Un registre local et une image

On lance un **registre d'images** local (`localhost:5000`) et on y publie deux images : `demo/app:1.0` (que l'on va signer) et `demo/non-signee:1.0` (qu'on laissera sans signature).

```bash
docker run -d --name registry -p 5000:5000 registry:2
docker pull -q alpine:3.20 && docker pull -q busybox:1.36
docker tag alpine:3.20 localhost:5000/demo/app:1.0
docker tag busybox:1.36 localhost:5000/demo/non-signee:1.0
docker push -q localhost:5000/demo/app:1.0
docker push -q localhost:5000/demo/non-signee:1.0
curl -s http://localhost:5000/v2/_catalog; echo
```{{exec}}

On signe le **digest** (le contenu), pas le tag (un tag peut être déplacé). Récupérons-le :

```bash
mkdir -p ~/cosign-lab && cd ~/cosign-lab
DIGEST=$(docker inspect --format '{{index .RepoDigests 0}}' localhost:5000/demo/app:1.0)
echo "$DIGEST" | tee digest.txt
```{{exec}}

## B. Générer une paire de clés

```bash
cd ~/cosign-lab
COSIGN_PASSWORD="" cosign generate-keypair
ls -l cosign.key cosign.pub
cat cosign.pub
```{{exec}}

`cosign.key` est la **clé privée** (protégée par un mot de passe, ici **vide** pour l'atelier : en vrai, un mot de passe fort **et** un KMS) ; `cosign.pub` est la **clé publique**, que l'on distribue à ceux qui vérifient.

## C. Signer l'image

```bash
cd ~/cosign-lab
COSIGN_PASSWORD="" cosign sign --key cosign.key --tlog-upload=false --yes "$(cat digest.txt)"
curl -s http://localhost:5000/v2/demo/app/tags/list; echo
```{{exec}}

La signature est **stockée dans le registre**, à côté de l'image, sous forme d'un tag `sha256-<digest>.sig` : visible dans la liste ci-dessus.

> ⚠️ **Attention** : `cosign.key` ne doit **jamais** être commitée ni partagée. Les clés d'un vrai projet vivent dans un **KMS** (`awskms://…`) ou une **CI keyless**.

## Questions

- Pourquoi signe-t-on le **digest** ? *(Un tag peut être réaffecté à une autre image ; le digest identifie le contenu exact.)*
- Où est stockée la signature ? *(Dans le registre, comme un artefact OCI lié au digest.)*

Cliquez sur **Vérifier**.
