#!/bin/bash
set -eo pipefail
export DEBIAN_FRONTEND=noninteractive

# -------------------------------------------------------------
# Color Definitions
# -------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log()     { echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"; }
error()   { echo -e "${RED}[ERROR] $1${NC}"; }
success() { echo -e "${GREEN}[OK] $1${NC}"; }
warn()    { echo -e "${YELLOW}[WARN] $1${NC}"; }

# -------------------------------------------------------------
# Root check
# -------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    error "Please run as root"
    exit 1
fi

# -------------------------------------------------------------
# Directories
# -------------------------------------------------------------
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
DDNS_DIR="/opt/ddns-go"
INFO_DIR="/opt/itedev-info"
mkdir -p "$DDNS_DIR" "$INFO_DIR"

# -------------------------------------------------------------
# Remove old version
# -------------------------------------------------------------
if [ -d "$DDNS_DIR" ]; then
    log "Removing old DDNS-GO installation..."
    rm -rf "$DDNS_DIR"
fi

# -------------------------------------------------------------
# Copy files
# -------------------------------------------------------------
log "Copying DDNS-GO files to $DDNS_DIR"
cp -r "$SCRIPT_DIR/../ddns-go/"* "$DDNS_DIR/"
chmod +x "$DDNS_DIR/ddns-go"

# -------------------------------------------------------------
# Create config file
# -------------------------------------------------------------
MACHINE_ID=$(cat /etc/machine-id)
CONFIG_FILE="$DDNS_DIR/config.yaml"
log "Creating config file at $CONFIG_FILE"

cat > "$CONFIG_FILE" << EOF
dnsconf:
    - name: ""
      ipv4:
        enable: true
        gettype: netInterface
        netinterface: tun114514
        domains:
            - ${MACHINE_ID}.control-network.internal.itedev.com
      dns:
        name: cloudflare
        id: "584970"
        secret: GL3_p-5nBKmqXSfejf3_8pOzI4dHVT2eFj9teUNn
      ttl: "60"
lang: zh
EOF

# -------------------------------------------------------------
# Install service
# -------------------------------------------------------------
log "Installing DDNS-GO service..."
"$DDNS_DIR/ddns-go" -s install -c "$CONFIG_FILE" -noweb -cacheTimes 20 -f 1

# -------------------------------------------------------------
# Create INFO file
# -------------------------------------------------------------
INFO_FILE="$INFO_DIR/internal-domain"
log "Creating INFO file at $INFO_FILE"
echo "${MACHINE_ID}.control-network.internal.itedev.com" > "$INFO_FILE"
chmod 444 "$INFO_FILE"

# -------------------------------------------------------------
# Finish
# -------------------------------------------------------------
success "DDNS-GO installed successfully!"
success "Internal domain: $(cat "$INFO_FILE")"