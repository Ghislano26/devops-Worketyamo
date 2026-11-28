# rocky9-devops.pkr.hcl — construit la box Vagrant « rocky9-devops » (Rocky Linux 9, VirtualBox).
#
# USAGE FORMATEUR UNIQUEMENT (les étudiants n'utilisent jamais Packer) :
#   cd environnement && make build-box
#
# Compatible Windows, macOS et Linux : seul le builder « virtualbox-iso » est actif.
# Le builder « qemu » est présent plus bas, ENTIÈREMENT COMMENTÉ (Linux uniquement).

packer {
  required_version = ">= 1.9.0"
  required_plugins {
    virtualbox = {
      version = ">= 1.0.5"
      source  = "github.com/hashicorp/virtualbox"
    }
    vagrant = {
      version = ">= 1.1.0"
      source  = "github.com/hashicorp/vagrant"
    }
    # LINUX UNIQUEMENT : décommenter avec le builder qemu (voir plus bas)
    # qemu = {
    #   version = ">= 1.0.10"
    #   source  = "github.com/hashicorp/qemu"
    # }
  }
}

# ---------------------------------------------------------------------------
# Variables épinglées
# ---------------------------------------------------------------------------
variable "rocky_version" {
  type        = string
  default     = "9.4"
  description = "Version de Rocky Linux de l'ISO de départ (la box embarque ensuite les mises à jour 9.x du jour du build)."
}

variable "box_version" {
  type        = string
  default     = "1.0.0"
  description = "Version de la box produite (à garder identique à vagrant/Vagrantfile)."
}

# Les ISO des versions mineures anciennes sont déplacées dans le « vault » de Rocky.
# Si l'URL ne répond plus, utiliser l'ISO de la version courante (voir README du dossier).
variable "iso_url" {
  type    = string
  default = "https://dl.rockylinux.org/vault/rocky/9.4/isos/x86_64/Rocky-9.4-x86_64-minimal.iso"
}

# À remplacer par l'empreinte officielle (fichier CHECKSUM publié à côté de l'ISO).
# Le « make build-box » refuse de lancer le build tant que cette valeur n'a pas été renseignée.
variable "iso_checksum" {
  type    = string
  default = "sha256:REMPLACER_PAR_CHECKSUM_OFFICIEL"
}

variable "headless" {
  type    = bool
  default = false
  # true : pas de fenêtre VirtualBox pendant le build (serveur d'intégration).
}

# ---------------------------------------------------------------------------
# Builder VirtualBox (Windows, macOS, Linux)
# ---------------------------------------------------------------------------
source "virtualbox-iso" "rocky9" {
  vm_name       = "rocky9-devops"
  guest_os_type = "RedHat_64"
  iso_url       = var.iso_url
  iso_checksum  = var.iso_checksum

  cpus      = 2
  memory    = 2048
  disk_size = 40000
  headless  = var.headless

  hard_drive_interface = "sata"
  iso_interface        = "sata"

  # Kickstart servi par le serveur HTTP temporaire de Packer (dossier http/).
  http_directory = "http"
  boot_wait      = "10s"
  # Menu BIOS (isolinux) de l'ISO Rocky : on remonte sur « Install », on édite la ligne de démarrage
  # et on y ajoute l'URL du kickstart.
  boot_command = [
    "<up><wait><tab><wait> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait>"
  ]

  ssh_username = "vagrant"
  ssh_password = "vagrant"
  ssh_timeout  = "30m"

  # Les Guest Additions sont envoyées dans la VM puis installées par scripts/01-base.sh
  # (nécessaires au dossier partagé /vagrant de type « virtualbox »).
  guest_additions_mode = "upload"
  guest_additions_path = "/tmp/VBoxGuestAdditions.iso"

  shutdown_command = "sudo /sbin/shutdown -h now"
}

# ---------------------------------------------------------------------------
# Builder QEMU — LINUX UNIQUEMENT, ne pas activer sur Windows/macOS.
# Produit une box pour le provider libvirt. Décommenter ce bloc ET le plugin qemu ci-dessus,
# puis utiliser la liste de sources « Linux » dans le bloc build.
# ---------------------------------------------------------------------------
# source "qemu" "rocky9" {
#   vm_name          = "rocky9-devops"
#   iso_url          = var.iso_url
#   iso_checksum     = var.iso_checksum
#   cpus             = 2
#   memory           = 2048
#   disk_size        = "40G"
#   format           = "qcow2"
#   accelerator      = "kvm"
#   headless         = true
#   http_directory   = "http"
#   boot_wait        = "10s"
#   boot_command     = [
#     "<up><wait><tab><wait> inst.text inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ks.cfg<enter><wait>"
#   ]
#   ssh_username     = "vagrant"
#   ssh_password     = "vagrant"
#   ssh_timeout      = "30m"
#   shutdown_command = "sudo /sbin/shutdown -h now"
# }

# ---------------------------------------------------------------------------
# Build
# ---------------------------------------------------------------------------
build {
  sources = ["source.virtualbox-iso.rocky9"]
  # Sur Linux : sources = ["source.virtualbox-iso.rocky9", "source.qemu.rocky9"]

  # 1) Mise à jour du système puis redémarrage : les Guest Additions doivent être compilées
  #    contre le noyau qui sera réellement utilisé.
  provisioner "shell" {
    execute_command = "echo 'vagrant' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    inline          = ["dnf -y update"]
  }

  provisioner "shell" {
    execute_command   = "echo 'vagrant' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    expect_disconnect = true
    inline            = ["systemctl reboot"]
    pause_after       = "40s"
  }

  # 2) Scripts de provisioning, dans l'ordre.
  provisioner "shell" {
    execute_command = "echo 'vagrant' | {{ .Vars }} sudo -S -E bash '{{ .Path }}'"
    scripts = [
      "../scripts/01-base.sh",
      "../scripts/02-devops-tools.sh",
      "../scripts/03-hardening.sh",
    ]
  }

  post-processor "vagrant" {
    output            = "rocky9-devops-${var.box_version}.box"
    compression_level = 9
  }
}
