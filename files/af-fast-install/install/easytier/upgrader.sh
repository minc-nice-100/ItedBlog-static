#!/bin/bash
set -eo pipefail
export DEBIAN_FRONTEND=noninteractive

# -------------------------------------------------------------
# Color definitions
# -------------------------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# -------------------------------------------------------------
# Constants
# -------------------------------------------------------------
readonly BASE_DIR="/opt/easytier"
readonly URL_BASE="https://static.itedev.com/files/af-fast-install/install/easytier"
readonly REMOTE_VERSION_URL="$URL_BASE/version"
readonly LOCAL_VERSION_FILE="$BASE_DIR/version"
readonly FILES="easytier-cli easytier-core version"
readonly SERVICE_NAME="easytier.service"

# -------------------------------------------------------------
# Logging functions
# -------------------------------------------------------------
log_info()    { echo -e "${BLUE}[$(date +'%F %T')] [INFO] $1${NC}"; }
log_warn()    { echo -e "${YELLOW}[$(date +'%F %T')] [WARN] $1${NC}"; }
log_error()   { echo -e "${RED}[$(date +'%F %T')] [ERROR] $1${NC}" >&2; exit 1; }
log_success() { echo -e "${GREEN}[$(date +'%F %T')] [OK] $1${NC}"; }

# -------------------------------------------------------------
# Root check
# -------------------------------------------------------------
[ "$(id -u)" -ne 0 ] && log_error "This script must be run as root."

# -------------------------------------------------------------
# Ensure BASE_DIR exists
# -------------------------------------------------------------
[ -d "$BASE_DIR" ] || log_error "Base directory $BASE_DIR does not exist."
cd "$BASE_DIR"

# -------------------------------------------------------------
# Trap to ensure service restarts on exit
# -------------------------------------------------------------
trap 'systemctl start '"$SERVICE_NAME" || true EXIT

# -------------------------------------------------------------
# Get local and remote version
# -------------------------------------------------------------
TMP_REMOTE="$(mktemp /tmp/remote_version.XXXXXX)"
curl -fsSL -H "Cache-Control: no-cache" "$REMOTE_VERSION_URL" -o "$TMP_REMOTE" || log_error "Failed to fetch remote version."

LOCAL_VER=""
[ -f "$LOCAL_VERSION_FILE" ] && LOCAL_VER=$(<"$LOCAL_VERSION_FILE")
REMOTE_VER=$(<"$TMP_REMOTE")

log_info "Local version: '$LOCAL_VER', Remote version: '$REMOTE_VER'"

if [ "$LOCAL_VER" = "$REMOTE_VER" ]; then
    log_info "Version is up-to-date, skipping update."
    rm -f "$TMP_REMOTE"
    exit 0
fi

log_info "New version detected, starting update..."
systemctl stop "$SERVICE_NAME"

# -------------------------------------------------------------
# Update files
# -------------------------------------------------------------
for f in $FILES; do
    log_info "Downloading $f ..."
    TMP_DL="$(mktemp "/tmp/${f}.XXXXXX")"
    curl -fsSL -H "Cache-Control: no-cache" "$URL_BASE/$f" -o "$TMP_DL" || log_error "Failed to download $f"

    # Compare MD5
    if [ -f "$BASE_DIR/$f" ]; then
        OLD_MD5=$(md5sum "$BASE_DIR/$f" | awk '{print $1}')
        NEW_MD5=$(md5sum "$TMP_DL" | awk '{print $1}')
        if [ "$OLD_MD5" = "$NEW_MD5" ]; then
            log_info "$f is unchanged, skipping replacement."
            rm -f "$TMP_DL"
            continue
        fi
    fi

    mv "$TMP_DL" "$BASE_DIR/$f"
done

chmod +x "$BASE_DIR"/easytier-*

log_success "Update completed, new version: '$REMOTE_VER'"
rm -f "$TMP_REMOTE"
