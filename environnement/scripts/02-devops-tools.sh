#!/usr/bin/env bash
# 02-devops-tools.sh — outils DevOps en versions épinglées (binaires officiels, architecture x86_64).
# Exécuté en root par Packer. Idempotent : un outil déjà présent à la bonne version n'est pas réinstallé.
set -euo pipefail

KUBECTL_VERSION="v1.30.5"
HELM_VERSION="v3.16.1"
TRIVY_VERSION="0.56.1"
SYFT_VERSION="v1.14.0"
ACT_VERSION="0.2.68"
SHELLCHECK_VERSION="v0.10.0"
YQ_VERSION="v4.44.3"

BIN_DIR="/usr/local/bin"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

log() { echo "==> [02-devops-tools] $*"; }

# Retourne 0 si la sortie de la commande de version contient la version attendue (sans « v »).
version_ok() {
  local commande="$1" attendue="${2#v}"
  command -v "${commande%% *}" >/dev/null 2>&1 || return 1
  local sortie
  # shellcheck disable=SC2086
  sortie="$($commande 2>&1)" || true
  grep -qF "$attendue" <<<"$sortie"
}

# Vérifie l'empreinte SHA-256 d'un fichier : verifier_sha256 <fichier> <empreinte>
verifier_sha256() {
  local fichier="$1" attendu="$2"
  echo "${attendu}  ${fichier}" | sha256sum --check --status \
    || { echo "ERREUR : empreinte SHA-256 invalide pour $(basename "$fichier")" >&2; exit 1; }
}

# --- kubectl -----------------------------------------------------------------------------------
if version_ok "kubectl version --client" "$KUBECTL_VERSION"; then
  log "kubectl $KUBECTL_VERSION déjà installé"
else
  log "Installation de kubectl $KUBECTL_VERSION"
  base="https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64"
  curl -fsSL -o "$TMP_DIR/kubectl" "$base/kubectl"
  verifier_sha256 "$TMP_DIR/kubectl" "$(curl -fsSL "$base/kubectl.sha256")"
  install -m 0755 "$TMP_DIR/kubectl" "$BIN_DIR/kubectl"
fi

# --- helm --------------------------------------------------------------------------------------
if version_ok "helm version --short" "$HELM_VERSION"; then
  log "helm $HELM_VERSION déjà installé"
else
  log "Installation de helm $HELM_VERSION"
  archive="helm-${HELM_VERSION}-linux-amd64.tar.gz"
  curl -fsSL -o "$TMP_DIR/$archive" "https://get.helm.sh/$archive"
  verifier_sha256 "$TMP_DIR/$archive" "$(curl -fsSL "https://get.helm.sh/$archive.sha256sum" | awk '{print $1}')"
  tar -xzf "$TMP_DIR/$archive" -C "$TMP_DIR" linux-amd64/helm
  install -m 0755 "$TMP_DIR/linux-amd64/helm" "$BIN_DIR/helm"
fi

# --- trivy -------------------------------------------------------------------------------------
if version_ok "trivy --version" "$TRIVY_VERSION"; then
  log "trivy $TRIVY_VERSION déjà installé"
else
  log "Installation de trivy $TRIVY_VERSION"
  archive="trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz"
  release="https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}"
  curl -fsSL -o "$TMP_DIR/$archive" "$release/$archive"
  verifier_sha256 "$TMP_DIR/$archive" \
    "$(curl -fsSL "$release/trivy_${TRIVY_VERSION}_checksums.txt" | awk -v f="$archive" '$2==f {print $1}')"
  tar -xzf "$TMP_DIR/$archive" -C "$TMP_DIR" trivy
  install -m 0755 "$TMP_DIR/trivy" "$BIN_DIR/trivy"
fi

# --- syft --------------------------------------------------------------------------------------
if version_ok "syft version" "$SYFT_VERSION"; then
  log "syft $SYFT_VERSION déjà installé"
else
  log "Installation de syft $SYFT_VERSION"
  v="${SYFT_VERSION#v}"
  archive="syft_${v}_linux_amd64.tar.gz"
  release="https://github.com/anchore/syft/releases/download/${SYFT_VERSION}"
  curl -fsSL -o "$TMP_DIR/$archive" "$release/$archive"
  verifier_sha256 "$TMP_DIR/$archive" \
    "$(curl -fsSL "$release/syft_${v}_checksums.txt" | awk -v f="$archive" '$2==f {print $1}')"
  tar -xzf "$TMP_DIR/$archive" -C "$TMP_DIR" syft
  install -m 0755 "$TMP_DIR/syft" "$BIN_DIR/syft"
fi

# --- act ---------------------------------------------------------------------------------------
if version_ok "act --version" "$ACT_VERSION"; then
  log "act $ACT_VERSION déjà installé"
else
  log "Installation de act $ACT_VERSION"
  archive="act_Linux_x86_64.tar.gz"
  release="https://github.com/nektos/act/releases/download/v${ACT_VERSION}"
  curl -fsSL -o "$TMP_DIR/$archive" "$release/$archive"
  verifier_sha256 "$TMP_DIR/$archive" \
    "$(curl -fsSL "$release/checksums.txt" | awk -v f="$archive" '$2==f {print $1}')"
  tar -xzf "$TMP_DIR/$archive" -C "$TMP_DIR" act
  install -m 0755 "$TMP_DIR/act" "$BIN_DIR/act"
fi

# --- shellcheck (pas de fichier d'empreintes publié : téléchargement HTTPS seul) ----------------
if version_ok "shellcheck --version" "$SHELLCHECK_VERSION"; then
  log "shellcheck $SHELLCHECK_VERSION déjà installé"
else
  log "Installation de shellcheck $SHELLCHECK_VERSION"
  archive="shellcheck-${SHELLCHECK_VERSION}.linux.x86_64.tar.xz"
  curl -fsSL -o "$TMP_DIR/$archive" \
    "https://github.com/koalaman/shellcheck/releases/download/${SHELLCHECK_VERSION}/$archive"
  tar -xJf "$TMP_DIR/$archive" -C "$TMP_DIR"
  install -m 0755 "$TMP_DIR/shellcheck-${SHELLCHECK_VERSION}/shellcheck" "$BIN_DIR/shellcheck"
fi

# --- yq (binaire unique) -------------------------------------------------------------------------
if version_ok "yq --version" "$YQ_VERSION"; then
  log "yq $YQ_VERSION déjà installé"
else
  log "Installation de yq $YQ_VERSION"
  curl -fsSL -o "$TMP_DIR/yq" "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
  install -m 0755 "$TMP_DIR/yq" "$BIN_DIR/yq"
fi

# --- Complétions bash ----------------------------------------------------------------------------
log "Complétions bash"
install -d /etc/bash_completion.d
kubectl completion bash > /etc/bash_completion.d/kubectl
helm completion bash    > /etc/bash_completion.d/helm
echo 'alias k=kubectl' > /etc/profile.d/kubectl-alias.sh

# --- Récapitulatif ---------------------------------------------------------------------------------
log "Versions installées :"
kubectl version --client | head -n 1
helm version --short
trivy --version | head -n 1
syft version | grep -i '^version'
act --version
shellcheck --version | grep '^version'
yq --version
