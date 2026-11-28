# Makefile — raccourcis pour ÉTUDIANTS : construire et piloter sa VM Rocky Linux 9.
# Prérequis : VirtualBox 7.x et Vagrant 2.4+ (voir ../GUIDE-ENVIRONNEMENT.md).
# Sous Windows : « make » n'est pas installé par défaut. Utilisez Git Bash ou WSL, ou lancez directement
# les commandes indiquées dans chaque cible (par exemple : cd vagrant ; vagrant up).

.PHONY: up ssh halt destroy status help

help:
	@echo "Cibles : up (construit/démarre la VM), ssh (s'y connecte), halt (l'éteint), destroy (la supprime), status"

up:
	cd vagrant && vagrant up

ssh:
	cd vagrant && vagrant ssh

halt:
	cd vagrant && vagrant halt

destroy:
	cd vagrant && vagrant destroy -f

status:
	cd vagrant && vagrant status

# ---------------------------------------------------------------------------------------------
# Cibles ci-dessous : RÉSERVÉES AU MODE AVANCÉ (construction d'une box custom avec Packer,
# voir packer-avance/README.md). Elles ne font PAS partie du chemin principal du cours.
# ---------------------------------------------------------------------------------------------
# build-box:
# 	@if grep -q 'REMPLACER_PAR_CHECKSUM_OFFICIEL' packer-avance/rocky9-devops.pkr.hcl; then \
# 	  echo "ERREUR : renseignez iso_checksum dans packer-avance/rocky9-devops.pkr.hcl"; exit 1; fi
# 	cd packer-avance && packer init . && packer build .
#
# clean:
# 	rm -rf packer-avance/output-* packer-avance/packer_cache
#
# release:
# 	@echo "Mode avancé : voir packer-avance/README.md pour utiliser ou partager la box produite."
