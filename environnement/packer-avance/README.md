# packer-avance/ — construire une box custom avec Packer (option avancée)

> ⚠️ **Packer est OPTIONNEL.** Il est réservé aux étudiants avancés et aux formateurs qui veulent produire leur **propre box**.
> **Le chemin principal du cours N'UTILISE PAS Packer** : il utilise la **box publique officielle `rockylinux/9`** et le **provisioning Vagrant** (`make up` depuis [`environnement/`](../README.md)). Si tu débutes, ignore ce dossier.

## À quoi ça sert ?

Le chemin principal télécharge la box publique `rockylinux/9`, puis installe les outils au premier `vagrant up` (5 à 15 minutes). Avec Packer, on fait ce travail **une seule fois** pour produire une box `rocky9-devops` **déjà provisionnée** : les `vagrant up` suivants (sur une ou plusieurs machines) sont alors beaucoup plus rapides, et tout le monde part d'un état identique.

| | Chemin principal (Vagrant) | Option avancée (Packer) |
|---|---|---|
| Box de départ | `rockylinux/9` (publique) | ISO Rocky Linux 9 + kickstart |
| Qui l'utilise | **Tous les étudiants** | Étudiants avancés, formateurs |
| Premier `vagrant up` | 5 à 15 min (provisioning) | 1 à 2 min (déjà provisionnée) |
| Identité entre machines | « Divergence contrôlée » (versions d'outils épinglées, paquets système à jour du jour) | Identique, figée dans la box |
| Installation requise | VirtualBox + Vagrant | + **Packer ≥ 1.9** |

## Contenu

```text
packer-avance/
├── README.md               ce fichier
├── rocky9-devops.pkr.hcl   définition de la box (builder VirtualBox ; builder qemu présent mais commenté, LINUX UNIQUEMENT)
└── http/ks.cfg             kickstart : installation automatique de Rocky Linux
```

Les provisioners du `.pkr.hcl` exécutent les **mêmes scripts** que le chemin principal (`../scripts/01-base.sh`, `02-devops-tools.sh`, `03-hardening.sh`). Le nettoyage d'empaquetage de `03-hardening.sh` ne s'active que sous Packer (variable `PACKER_BUILD_NAME`).

## Construire la box

Prérequis : **Packer ≥ 1.9** (<https://developer.hashicorp.com/packer/downloads>), VirtualBox 7.x, ≈ 20 Go libres, connexion Internet.

1. **Renseigner l'empreinte de l'ISO** : ouvre le fichier `CHECKSUM` publié à côté de l'ISO (même dossier que `iso_url`) et copie la ligne SHA-256 de `Rocky-9.4-x86_64-minimal.iso` dans `rocky9-devops.pkr.hcl` :

   ```hcl
   variable "iso_checksum" { default = "sha256:<empreinte officielle>" }
   ```

   > L'ISO 9.4 se trouve dans le *vault* de Rocky (`dl.rockylinux.org/vault/...`). Si l'URL ne répond plus, prends la version courante sur <https://rockylinux.org/download> et mets à jour `iso_url`, `iso_checksum` **et** les deux URL de dépôts de `http/ks.cfg`.

2. **Lancer le build** (15 à 30 minutes) :

   ```bash
   cd environnement/packer-avance
   packer init .
   packer build .
   ```

   > **Windows** : autorise Packer dans le pare-feu quand il le demande (serveur HTTP temporaire qui sert `ks.cfg` à la VM).

3. **Résultat** : `rocky9-devops-1.0.0.box` (≈ 1,5 Go), **ignoré par Git** (`*.box`).

## Utiliser la box produite

```bash
vagrant box add --name rocky9-devops packer-avance/rocky9-devops-1.0.0.box
```

Puis, dans `vagrant/Vagrantfile`, remplace la box publique et **retire** les 3 provisioners (la box est déjà provisionnée) :

```ruby
config.vm.box = "rocky9-devops"
config.vm.box_version = "1.0.0"
# supprimer les lignes config.vm.provision "shell", name: "01-base" / "02-devops-tools" / "03-hardening"
```

Garde la dernière provision (« verification ») pour contrôler les outils.

## Limites

- Ces fichiers n'ont **jamais été exécutés de bout en bout** : le premier `packer build` est à tester et à corriger si besoin (menu de démarrage de l'ISO, installation des Guest Additions, URL des binaires).
- Box **x86_64 uniquement** (pas d'Apple Silicon).
- Le builder `qemu` du fichier est **commenté** : il est réservé à Linux, ne l'active pas sous Windows ou macOS.
