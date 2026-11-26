#!/usr/bin/env python3
"""check-killercoda.py — valide un dépôt de scénarios Killercoda AVANT de le pousser.

Usage :
    python3 scripts/check-killercoda.py [dossier]      # défaut : la racine du dépôt

Contrôles :
  1. structure.json existe, est du JSON valide et ne contient que des items avec « path » ;
  2. chaque path désigne un dossier qui contient un index.json valide ;
  3. index.json référence des fichiers qui existent (intro, text.md, verify.sh, finish) ;
  4. chaque verify.sh est exécutable et passe « bash -n » ;
  5. le backend (imageid) est renseigné ;
  6. les noms de scénarios (dernier segment du chemin) sont uniques ;
  7. AVERTISSEMENT : les scénarios présents dans le dépôt mais absents de structure.json
     (Killercoda les ignore dès qu'un structure.json existe).

Code de retour : 0 si aucune erreur (les avertissements ne comptent pas), 1 sinon.
"""
import json
import os
import subprocess
import sys

racine = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), ".."))
erreurs, avertissements = [], []


def err(msg):
    erreurs.append(msg)
    print(f"  ✘ {msg}")


def ok(msg):
    print(f"  ✔ {msg}")


def charge(chemin):
    try:
        with open(chemin, encoding="utf-8") as f:
            return json.load(f)
    except FileNotFoundError:
        return None
    except json.JSONDecodeError as e:
        err(f"{os.path.relpath(chemin, racine)} : JSON invalide ({e})")
        return None


print(f"Dépôt analysé : {racine}\n")
structure = charge(os.path.join(racine, "structure.json"))
if structure is None:
    print("structure.json est absent ou invalide : rien à contrôler.")
    sys.exit(1)

items = structure.get("items")
if not isinstance(items, list) or not items:
    err("structure.json doit contenir un tableau « items » non vide.")
    items = []

declares = []
for it in items:
    chemin = it.get("path") if isinstance(it, dict) else None
    if not chemin:
        err(f"item sans « path » : {it}")
        continue
    declares.append(os.path.normpath(chemin))

noms = {}
for chemin in declares:
    print(f"\n● {chemin}")
    noms.setdefault(os.path.basename(chemin), []).append(chemin)
    dossier = os.path.join(racine, chemin)
    if not os.path.isdir(dossier):
        err("dossier introuvable")
        continue
    idx = charge(os.path.join(dossier, "index.json"))
    if idx is None:
        err("index.json absent ou invalide")
        continue
    backend = (idx.get("backend") or {}).get("imageid")
    if not backend:
        err("backend.imageid manquant dans index.json")
    else:
        ok(f"backend : {backend}")
    details = idx.get("details") or {}
    refs = []
    if (details.get("intro") or {}).get("text"):
        refs.append(details["intro"]["text"])
    else:
        err("details.intro.text manquant")
    if (details.get("finish") or {}).get("text"):
        refs.append(details["finish"]["text"])
    else:
        err("details.finish.text manquant")
    etapes = details.get("steps") or []
    if not etapes:
        err("aucune étape (details.steps)")
    verifs = []
    for i, e in enumerate(etapes, 1):
        for cle in ("text", "verify"):
            if not e.get(cle):
                err(f"étape {i} : « {cle} » manquant")
        if e.get("text"):
            refs.append(e["text"])
        if e.get("verify"):
            refs.append(e["verify"])
            verifs.append(e["verify"])
    manquants = [r for r in refs if not os.path.isfile(os.path.join(dossier, r))]
    for r in manquants:
        err(f"fichier référencé introuvable : {r}")
    for r in refs:
        p = os.path.join(dossier, r)
        if os.path.isfile(p) and os.path.getsize(p) == 0:
            err(f"fichier vide : {r}")
    for v in verifs:
        p = os.path.join(dossier, v)
        if not os.path.isfile(p):
            continue
        if not os.access(p, os.X_OK):
            err(f"{v} n'est pas exécutable (chmod +x)")
        r = subprocess.run(["bash", "-n", p], capture_output=True, text=True)
        if r.returncode != 0:
            err(f"{v} : erreur de syntaxe Bash : {r.stderr.strip()}")
    if not manquants:
        ok(f"{len(etapes)} étape(s), {len(refs)} fichier(s) référencé(s) présents")

print("\n● Unicité des noms de scénarios")
doublons = {n: c for n, c in noms.items() if len(c) > 1}
if doublons:
    for n, c in doublons.items():
        err(f"nom « {n} » utilisé plusieurs fois : {', '.join(c)}")
else:
    ok("tous les noms sont uniques")

print("\n● Scénarios présents dans le dépôt mais absents de structure.json")
orphelins = []
for dossier, sous, fichiers in os.walk(racine):
    sous[:] = [d for d in sous if d not in (".git", "node_modules")]
    if "index.json" in fichiers and os.path.abspath(dossier) != racine:
        rel = os.path.normpath(os.path.relpath(dossier, racine))
        if rel not in declares:
            orphelins.append(rel)
if orphelins:
    for o in sorted(orphelins):
        avertissements.append(o)
        print(f"  ⚠ {o}  (ignoré par Killercoda tant qu'il n'est pas dans structure.json)")
else:
    ok("aucun")

print(f"\nRésultat : {len(declares)} scénario(s) déclaré(s), {len(erreurs)} erreur(s), {len(avertissements)} avertissement(s).")
sys.exit(1 if erreurs else 0)
