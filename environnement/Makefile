# Makefile — réservé au FORMATEUR (construction et publication de la box).
# Prérequis : Packer >= 1.9 et VirtualBox 7.x. Sous Windows : lancer « make » depuis Git Bash ou WSL ;
# à défaut, exécuter à la main les commandes indiquées dans chaque cible.

BOX_VERSION ?= 1.0.0
BOX_FILE    := packer/rocky9-devops-$(BOX_VERSION).box

.PHONY: build-box clean release help

help:
	@echo "Cibles : build-box (construit la box), clean (nettoie), release (instructions de publication)"

build-box:
	@if grep -q 'REMPLACER_PAR_CHECKSUM_OFFICIEL' packer/rocky9-devops.pkr.hcl; then \
	  echo "ERREUR : renseignez la variable iso_checksum dans packer/rocky9-devops.pkr.hcl (empreinte officielle de l'ISO)."; \
	  exit 1; \
	fi
	cd packer && packer init . && packer build .

clean:
	rm -rf packer/output-* packer/packer_cache

release:
	@echo "Publication de la box $(BOX_VERSION) sur GitHub Releases :"
	@echo "  1. Vérifier que le fichier existe : $(BOX_FILE)"
	@echo "  2. Calculer l'empreinte :  sha256sum $(BOX_FILE)   (Windows : Get-FileHash -Algorithm SHA256)"
	@echo "  3. Créer la release :  https://github.com/Ghislano26/devops-Worketyamo/releases/new"
	@echo "       - tag : v$(BOX_VERSION)   - titre : « Box rocky9-devops $(BOX_VERSION) »"
	@echo "       - joindre $(BOX_FILE) ; coller le SHA-256 et le changelog dans la description"
	@echo "  4. Ou avec gh :  gh release create v$(BOX_VERSION) $(BOX_FILE) --title \"Box rocky9-devops $(BOX_VERSION)\" --notes-file notes.md"
	@echo "  5. Mettre à jour l'annexe F de GUIDE-ENVIRONNEMENT.md (date du build) et communiquer l'URL à la promotion."
