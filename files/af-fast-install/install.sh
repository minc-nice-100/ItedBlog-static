#!/bin/bash
set -eo pipefail

# -----------------------------
# 彩色日志
# -----------------------------
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'
log() { echo -e "${BLUE}[$(date '+%F %T')]${NC} $*"; }
log_success() { echo -e "${GREEN}[$(date '+%F %T')]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[$(date '+%F %T')]${NC} $*"; }
log_error() { echo -e "${RED}[$(date '+%F %T')] ERROR: $*${NC}" >&2; exit 1; }

# -----------------------------
# Root check
# -----------------------------
[ "$(id -u)" -ne 0 ] && log_error "Must run as root"

# -----------------------------
# Parse arguments
# -----------------------------
TOKEN=""
while getopts ":t:" opt; do
  case $opt in
    t) TOKEN="$OPTARG";;
    \?) log_error "Usage: $0 [-t <token>]";;
  esac
done

# -----------------------------
# Directories & URLs
# -----------------------------
INSTALL_PKG_URL="https://static.itedev.com/files/af-fast-install/package.tar.gz"
TMP_DIR=$(mktemp -d /tmp/install-all-XXXXXX)
PACKAGE="$TMP_DIR/package.tar.gz"
INSTALLER_DIR="$TMP_DIR/package/install/installer"
INFO_DIR="/opt/itedev-info/"
mkdir -p "$INFO_DIR"

# -----------------------------
# Cleanup
# -----------------------------
cleanup() {
    local exit_code=$?
    log "Cleaning up temporary files..."
    rm -rf "$TMP_DIR" 2>/dev/null || true
    rm -f /tmp/easytier-* /tmp/ddns-go-* /tmp/beszel-* 2>/dev/null || true
    if [ $exit_code -ne 0 ]; then
        log_error "Script exited with code $exit_code. Cleanup done."
    else
        log_success "Cleanup completed successfully."
    fi
}
trap cleanup EXIT INT TERM HUP QUIT

# -----------------------------
# Download package
# -----------------------------
log "Downloading installation package..."
if ! wget -q --show-progress "$INSTALL_PKG_URL" -O "$PACKAGE"; then
    log_error "Failed to download $INSTALL_PKG_URL"
fi

[ -s "$PACKAGE" ] || log_error "Downloaded package is empty"

# -----------------------------
# Extract package
# -----------------------------
log "Extracting package..."
mkdir -p "$TMP_DIR/package"
if ! tar -zxvf "$PACKAGE" -C "$TMP_DIR/package"; then
    log_error "Extraction failed"
fi

[ -d "$INSTALLER_DIR" ] || log_error "Installer directory not found after extraction: $INSTALLER_DIR"

# -----------------------------
# Run installer component
# -----------------------------
run_component() {
    local script="$1"
    local name=$(basename "$script" .sh)
    chmod +x "$script"
    log "Installing $name..."

    if [[ "$name" == "beszel-agent" ]]; then
        [ -z "$TOKEN" ] && log_error "Missing required -t <token> for beszel-agent"
        bash "$script" -t "$TOKEN"
    else
        bash "$script"
    fi

    log_success "$name installation completed"
}

# -----------------------------
# Auto-discover and install
# -----------------------------
log "Scanning for installer scripts in $INSTALLER_DIR..."
shopt -s nullglob
for script in "$INSTALLER_DIR"/*.sh; do
    run_component "$script"
done
shopt -u nullglob

# -----------------------------
# Post-install summary
# -----------------------------
log_success "All components installed successfully!"
[ -f "$INFO_DIR/internal-domain" ] && log "Control network domain: $(cat "$INFO_DIR/internal-domain")" || log_warn "internal-domain file not found"

log "Script finished."
exit 0
