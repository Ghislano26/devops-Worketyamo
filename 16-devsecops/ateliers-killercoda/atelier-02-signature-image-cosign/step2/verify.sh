#!/bin/bash
d="$HOME/cosign-lab"
command -v cosign >/dev/null 2>&1 || { echo "cosign n'est pas installé."; exit 1; }
curl -fs --max-time 5 http://localhost:5000/v2/_catalog >/dev/null || { echo "Le registre local ne répond plus (docker ps ; docker start registry)."; exit 1; }
[ -x "$d/admission.sh" ] || { echo "Le script $d/admission.sh est absent ou non exécutable (partie D : chmod +x)."; exit 1; }
grep -q 'cosign verify' "$d/admission.sh" || { echo "admission.sh doit appeler « cosign verify »."; exit 1; }
cd "$d" || exit 1
cosign verify --key cosign.pub --insecure-ignore-tlog=true localhost:5000/demo/app:1.0 >/dev/null 2>&1 || { echo "demo/app:1.0 ne passe plus la vérification : le tag a-t-il été remis sur l'image d'origine (partie C, seconde commande) ?"; exit 1; }
if cosign verify --key cosign.pub --insecure-ignore-tlog=true localhost:5000/demo/non-signee:1.0 >/dev/null 2>&1; then echo "demo/non-signee:1.0 ne doit PAS être signée : ne la signez pas."; exit 1; fi
"$d/admission.sh" localhost:5000/demo/app:1.0 >/dev/null 2>&1 || { echo "admission.sh doit ADMETTRE (code 0) l'image signée demo/app:1.0."; exit 1; }
if "$d/admission.sh" localhost:5000/demo/non-signee:1.0 >/dev/null 2>&1; then echo "admission.sh doit REFUSER (code non nul) l'image non signée demo/non-signee:1.0."; exit 1; fi
digest=$(docker inspect --format '{{index .RepoDigests 0}}' localhost:5000/demo/app:1.0 2>/dev/null)
[ -n "$digest" ] && [ "$digest" = "$(cat "$d/digest.txt" 2>/dev/null)" ] || { echo "Le digest actuel de demo/app:1.0 diffère de celui signé (digest.txt) : repoussez l'image alpine:3.20 sous ce tag."; exit 1; }
echo "OK : image signée admise, image non signée refusée, tag réécrit détecté puis restauré (digest conforme à celui signé)."
exit 0
