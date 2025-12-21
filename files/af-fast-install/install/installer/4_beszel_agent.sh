#!/bin/bash
set -eo pipefail

# -------------------------------------------------------------
# Color logging
# -------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[$(date '+%F %T')]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}[$(date '+%F %T')]${NC} $1"; }
log_error()   { echo -e "${RED}[$(date '+%F %T')]${NC} $1"; exit 1; }
log_success() { echo -e "${GREEN}[$(date '+%F %T')]${NC} $1"; }

# -------------------------------------------------------------
# Check root
# -------------------------------------------------------------
[ "$(id -u)" -ne 0 ] && log_error "This script must be run as root"

# -------------------------------------------------------------
# Parse arguments
# -------------------------------------------------------------
TOKEN=""
while getopts ":t:" opt; do
  case $opt in
    t) TOKEN="$OPTARG";;
    \?) log_error "Usage: $0 -t <token>";;
  esac
done
shift $((OPTIND -1))
[ -z "$TOKEN" ] && log_error "Missing required -t parameter"

# -------------------------------------------------------------
# Prepare directories
# -------------------------------------------------------------
BASE_DIR="/opt/beszel-agent"
mkdir -p "$BASE_DIR"

# -------------------------------------------------------------
# Download and run installer
# -------------------------------------------------------------
log_info "Downloading Beszel Agent installer..."
curl -sSL https://get.beszel.dev -o /tmp/install-agent.sh
chmod +x /tmp/install-agent.sh

log_info "Running Beszel Agent installer..."
/tmp/install-agent.sh -p 45876 \
  -k "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAnKR+p5h6rehBbitM9bD/c2NOUbMdIqu4zRAjid8zX4" \
  --china-mirrors \
  --auto-update \
  -url "http://e57ff0a24e7f4813a03786276e59755a.control-network.internal.itedev.com:8090" \
  -t "$TOKEN"

# -------------------------------------------------------------
# Detect network for mirrors
# -------------------------------------------------------------
log_info "Detecting network environment..."
if curl -s --connect-timeout 5 https://www.google.com >/dev/null 2>&1; then
    log_info "Using international mirrors"
    UPDATE_CMD="/opt/beszel-agent/beszel-agent update"
else
    log_info "Using China mirrors"
    UPDATE_CMD="/opt/beszel-agent/beszel-agent update --china-mirrors https://git.itedev.com/https://github.com/"
fi

# -------------------------------------------------------------
# Generate run-update.sh
# -------------------------------------------------------------
cat > /opt/beszel-agent/run-update.sh <<EOF
#!/bin/sh
$UPDATE_CMD
systemctl restart beszel-agent
exit 0
EOF
chmod +x /opt/beszel-agent/run-update.sh

# -------------------------------------------------------------
# Completion
# -------------------------------------------------------------
log_success "Beszel Agent installation completed successfully!"
