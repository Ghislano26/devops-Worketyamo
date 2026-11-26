# Chaos engineering basique

**Durée : ~30 minutes.** Compétence travaillée : mener une **expérience de chaos** contrôlée sur Kubernetes : état stable, hypothèse, injection, observation, retour arrière.

Rappel du [cours Chaos engineering](https://github.com/Ghislano26/devops-Worketyamo/blob/main/11-sre-pratiques/cours/06-chaos-engineering.md) :

```text
État stable (SLI) → HYPOTHÈSE → injection de panne → observation → analyse → retour arrière → actions
```

| Principe | Application dans cet atelier |
|---|---|
| Hypothèse écrite **avant** | `~/chaos/experience.md` |
| **Blast radius** limité | 1 pod sur 3 |
| **Condition d'arrêt** | Plus de 2 échecs consécutifs |
| **Retour arrière** | `kubectl scale …` ; `tc qdisc del …` |
| Observer **en direct** | Une sonde qui interroge le Service en continu |

> ⚠️ Cet atelier tourne dans un environnement **jetable**. Ne reproduisez jamais ces perturbations sur une production sans préparation, accord de l'équipe et budget d'erreur disponible.

## Vérifions le cluster

```bash
kubectl get nodes
```{{exec}}

Le nœud doit être `Ready`.
