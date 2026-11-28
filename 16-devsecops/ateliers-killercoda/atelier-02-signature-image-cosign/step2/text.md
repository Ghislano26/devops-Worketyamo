# Étape 2 : vérifier, détecter, refuser

## A. Vérifier une image signée

```bash
cd ~/cosign-lab
cosign verify --key cosign.pub --insecure-ignore-tlog=true localhost:5000/demo/app:1.0 | jq .
```{{exec}}

La sortie indique le **digest vérifié** et l'identité de la signature. Une signature n'est valable **que pour ce digest**.

## B. Une image non signée échoue

```bash
cd ~/cosign-lab
cosign verify --key cosign.pub --insecure-ignore-tlog=true localhost:5000/demo/non-signee:1.0; echo "code de sortie : $?"
```{{exec}}

Message attendu : *no signatures found*, code de sortie **non nul**.

## C. Un tag réécrit est détecté

Simulons une attaque : quelqu'un **remplace l'image** derrière le tag `demo/app:1.0` (ici par `busybox`) :

```bash
cd ~/cosign-lab
docker tag busybox:1.36 localhost:5000/demo/app:1.0
docker push -q localhost:5000/demo/app:1.0
cosign verify --key cosign.pub --insecure-ignore-tlog=true localhost:5000/demo/app:1.0; echo "code de sortie : $?"
```{{exec}}

La vérification **échoue** : le tag pointe maintenant vers un **autre digest**, qui n'a pas de signature. Remettons la bonne image (le digest d'origine est conservé dans `digest.txt`) :

```bash
cd ~/cosign-lab
docker tag alpine:3.20 localhost:5000/demo/app:1.0
docker push -q localhost:5000/demo/app:1.0
cosign verify --key cosign.pub --insecure-ignore-tlog=true localhost:5000/demo/app:1.0 >/dev/null && echo "signature de nouveau valide"
```{{exec}}

## D. Un « contrôleur d'admission » simulé

Dans Kubernetes, **Kyverno** ou **Connaisseur** intercepteraient la création d'un pod et vérifieraient la signature. On simule ce comportement avec un script qui **refuse de lancer** toute image sans signature valide :

```bash
cd ~/cosign-lab
cat > admission.sh <<'EOF'
#!/bin/bash
# Simule un contrôleur d'admission : n'autorise que les images signées avec notre clé
IMAGE="$1"
CLE="$HOME/cosign-lab/cosign.pub"
if cosign verify --key "$CLE" --insecure-ignore-tlog=true "$IMAGE" >/dev/null 2>&1; then
  echo "ADMISE  : signature valide pour $IMAGE"
  exit 0
else
  echo "REFUSÉE : aucune signature valide pour $IMAGE"
  exit 1
fi
EOF
chmod +x admission.sh
./admission.sh localhost:5000/demo/app:1.0 && docker run --rm localhost:5000/demo/app:1.0 echo "conteneur lancé : image signée"
./admission.sh localhost:5000/demo/non-signee:1.0 && docker run --rm localhost:5000/demo/non-signee:1.0 echo "ne doit jamais s'afficher"
echo "code de sortie : $?"
```{{exec}}

La première image est **admise et lancée**, la seconde est **refusée** : `docker run` n'est jamais exécuté.

> 💡 **Conseil** : dans un vrai cluster, cette vérification ne peut pas être contournée par un utilisateur : le contrôleur d'admission est dans le chemin de **toute** création de pod. Ici, le script n'a de valeur que pédagogique : quelqu'un peut très bien lancer `docker run` sans passer par lui.

## Questions

- Que se passe-t-il si l'on perd ou divulgue `cosign.key` ? *(Un attaquant peut signer des images malveillantes que votre vérification acceptera : il faut **révoquer** la clé publique et en distribuer une nouvelle ; d'où les KMS et le mode keyless.)*
- Pourquoi le mode **keyless** supprime-t-il ce risque ? *(Aucune clé durable : un certificat de 10 minutes lié à l'identité de la CI ; voir le [cours 3](https://github.com/Ghislano26/devops-Worketyamo/blob/main/16-devsecops/cours/03-signature-et-provenance.md).)*

Cliquez sur **Vérifier**.
