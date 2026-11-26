# Étape 1 : l'état stable avant toute expérience

Une expérience de chaos commence par un **état stable mesurable** (voir le [cours 06](https://github.com/Ghislano26/devops-Worketyamo/blob/main/11-sre-pratiques/cours/06-chaos-engineering.md)). Déployez une application **nginx** (3 réplicas) derrière un **Service** :

```bash
kubectl create deployment web --image=nginx:1.27 --replicas=3
kubectl expose deployment web --port=80
kubectl rollout status deployment/web
kubectl get pods -l app=web -o wide
kubectl get svc web
```{{exec}}

## Mesurer l'état stable

Interrogez le Service depuis un pod client temporaire, **plusieurs fois**, et mesurez la latence de bout en bout :

```bash
kubectl run client --rm -i --restart=Never --image=busybox:1.36 -- sh -c '
  ok=0; for i in $(seq 1 20); do wget -q -O /dev/null -T 3 http://web && ok=$((ok+1)); done
  echo "succès : $ok / 20"'
```{{exec}}

Notez : **20/20** de succès, **3 pods `Ready`**. C'est votre **état stable** (vos « SLI »).

## Écrire l'hypothèse (avant d'agir !)

Créez le dossier de travail et notez votre expérience dans `~/chaos/experience.md` :

```bash
mkdir -p ~/chaos
cat > ~/chaos/experience.md <<'EOF'
# Expérience : suppression d'un pod du Deployment « web »
- État stable : 3 pods Ready ; 20/20 requêtes réussies via le Service
- Hypothèse : si l'on supprime UN pod, le Service continue de répondre (aucune erreur visible)
  et le Deployment recrée un pod pour revenir à 3 réplicas en moins de 60 s.
- Périmètre (blast radius) : 1 pod sur 3, environnement d'atelier
- Condition d'arrêt : plus de 2 échecs consécutifs sur 20 requêtes
- Retour arrière : kubectl scale deployment web --replicas=3
EOF
cat ~/chaos/experience.md
```{{exec}}

> Pourquoi écrire l'hypothèse **avant** ? Pour ne pas la reformuler après coup en fonction du résultat : c'est ce qui rend l'expérience **scientifique**.

Cliquez sur **Vérifier**.
