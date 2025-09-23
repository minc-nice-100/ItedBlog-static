#!/bin/bash

# Predefined color codes
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Constants
readonly REQUIRED_SPACE=100
readonly INSTALL_DIR="/opt/easytier"
readonly CONFIG_FILE="${INSTALL_DIR}/config/config.yaml"
readonly SERVICE_NAME="easytier"
readonly UPGRADER_SCRIPT="${INSTALL_DIR}/upgrader.sh"

# Get the absolute path of the script
readonly SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Function to print error and exit
error_exit() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Function to print status message
print_status() {
    echo -e "${YELLOW}$1...${NC}"
}

# Function to print success message
print_success() {
    echo -e "${GREEN}$1${NC}"
}

# Check if the script is run as root
[ "$(id -u)" -ne 0 ] && error_exit "This script must be run as root. Please use sudo."

# Installation pre-check list
print_status "Performing system environment checks"

# Check systemd availability
command -v systemctl >/dev/null 2>&1 || error_exit "System does not use systemd as the init system."

# Check system architecture
[ "$(uname -m)" != "x86_64" ] && error_exit "Current architecture $(uname -m) is not supported. Only x86_64 architecture is supported."

# Check disk space
available_space=$(df -m "${INSTALL_DIR%/*}" | awk 'NR==2 {print $4}')
[ "$available_space" -lt "$REQUIRED_SPACE" ] && error_exit "Insufficient disk space in ${INSTALL_DIR%/*} partition (required ${REQUIRED_SPACE}MB, available ${available_space}MB)."

# Installation process starts
print_success "Starting installation of EasyTier..."

# Create installation directory
print_status "Creating installation directory ${INSTALL_DIR}"
mkdir -p "${INSTALL_DIR}" || error_exit "Unable to create installation directory."

# Copy files
print_status "Copying application files"
cp -rv "${SCRIPT_DIR}/../easytier"/* "${INSTALL_DIR}/" || error_exit "File copy failed. Please check the integrity of the source files."

# Set permissions
print_status "Setting file permissions"
find "${INSTALL_DIR}" -type f -exec chmod 644 {} \;
find "${INSTALL_DIR}" -type d -exec chmod 755 {} \;
chmod +x "${INSTALL_DIR}/easytier-core"
chmod +x "${UPGRADER_SCRIPT}"  # 确保升级脚本有执行权限

# Check configuration file
[ ! -f "${CONFIG_FILE}" ] && error_exit "Configuration file missing: ${CONFIG_FILE}"

# Check upgrader script
[ ! -f "${UPGRADER_SCRIPT}" ] && error_exit "Upgrader script missing: ${UPGRADER_SCRIPT}"

# Install system service
print_status "Configuring system service"
cat > "/etc/systemd/system/${SERVICE_NAME}.service" << EOF
[Unit]
Description=EasyTier Network Service
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
WorkingDirectory=${INSTALL_DIR}
ExecStart=${INSTALL_DIR}/easytier-core --config-server wss://easytier-config-server.itedev.com:8443/root --machine-id $(cat /etc/machine-id)
Restart=always
RestartSec=3
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=${SERVICE_NAME}

# Security enhancements
NoNewPrivileges=yes
ProtectSystem=strict
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd configuration
systemctl daemon-reload || error_exit "systemd configuration reload failed."

# Enable and start service
print_status "Starting system service"
if ! systemctl enable --now "${SERVICE_NAME}.service"; then
    error_exit "Service start failed. Check logs: journalctl -u ${SERVICE_NAME}.service -n 50 --no-pager"
fi

# Verify service status
print_status "Verifying service status"
sleep 2 # Wait for service initialization
if ! systemctl is-active --quiet "${SERVICE_NAME}.service"; then
    error_exit "Service is not running properly. Check logs: journalctl -u ${SERVICE_NAME}.service -n 100 --no-pager"
fi

# Configure auto-upgrade
print_status "Configuring auto-upgrade"
cat > "/etc/systemd/system/${SERVICE_NAME}-upgrade.service" << EOF
[Unit]
Description=EasyTier 自动更新

[Service]
Type=oneshot
ExecStart=${UPGRADER_SCRIPT}
User=root
Group=root
EOF

cat > "/etc/systemd/system/${SERVICE_NAME}-upgrade.timer" << EOF
[Unit]
Description=每小时检查 EasyTier 更新

[Timer]
OnBootSec=5min
OnUnitActiveSec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl daemon-reload || error_exit "Failed to reload systemd configuration for upgrade service"
systemctl enable --now "${SERVICE_NAME}-upgrade.timer" || error_exit "Failed to enable upgrade timer"

# Post-installation checks
print_status "Verifying installation result"
echo "Version information:"
"${INSTALL_DIR}/easytier-core" --version || error_exit "Unable to retrieve version information."

print_success "\nInstallation successful! EasyTier service is running."
echo -e "Service management commands:"
echo -e "  Start service: systemctl start ${SERVICE_NAME}"
echo -e "  Stop service: systemctl stop ${SERVICE_NAME}"
echo -e "  Check status: systemctl status ${SERVICE_NAME}"
echo -e "  View logs: journalctl -u ${SERVICE_NAME} -f"
