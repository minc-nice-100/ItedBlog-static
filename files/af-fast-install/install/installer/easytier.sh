#!/bin/bash

# Predefined color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the absolute path of the script
script_dir=$(dirname "$(readlink -f "$0")")

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root. Please use sudo.${NC}"
    exit 1
fi

# Installation pre-check list
echo -e "${YELLOW}Performing system environment checks...${NC}"

# Check systemd availability
if ! command -v systemctl >/dev/null 2>&1; then
    echo -e "${RED}Error: System does not use systemd as the init system.${NC}"
    exit 1
fi

# Check system architecture
arch=$(uname -m)
if [ "$arch" != "x86_64" ]; then
    echo -e "${RED}Error: Current architecture ${arch} is not supported. Only x86_64 architecture is supported.${NC}"
    exit 1
fi

# Check disk space (at least 100MB)
required_space=100
available_space=$(df -m /opt | awk 'NR==2 {print $4}')
if [ "$available_space" -lt "$required_space" ]; then
    echo -e "${RED}Error: Insufficient disk space in /opt partition (required ${required_space}MB, available ${available_space}MB).${NC}"
    exit 1
fi

# Installation process starts
echo -e "${GREEN}Starting installation of EasyTier...${NC}"

# Create installation directory
echo "Creating installation directory /opt/easytier"
if ! mkdir -p /opt/easytier; then
    echo -e "${RED}Error: Unable to create installation directory.${NC}"
    exit 1
fi

# Copy files (with error handling)
echo "Copying application files..."
if ! cp -rv "${script_dir}/../easytier"/* /opt/easytier/; then
    echo -e "${RED}Error: File copy failed. Please check the integrity of the source files.${NC}"
    exit 1
fi

# Set permissions
echo "Setting file permissions..."
find /opt/easytier -type f -exec chmod 644 {} \;
find /opt/easytier -type d -exec chmod 755 {} \;
chmod +x /opt/easytier/easytier-core

# Check configuration file
config_file="/opt/easytier/config/config.yaml"
if [ ! -f "$config_file" ]; then
    echo -e "${RED}Error: Configuration file missing: ${config_file}.${NC}"
    exit 1
fi

# Install system service
echo "Configuring system service..."
cat > /etc/systemd/system/easytier.service << EOF
[Unit]
Description=EasyTier Network Service
Wants=network-online.target
After=network-online.target
StartLimitIntervalSec=0

[Service]
Type=simple
WorkingDirectory=/opt/easytier
ExecStart=/opt/easytier/easytier-core -c $config_file
Restart=always
RestartSec=3
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=easytier

# Security enhancements
NoNewPrivileges=yes
ProtectSystem=strict
PrivateTmp=yes

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd configuration
if ! systemctl daemon-reload; then
    echo -e "${RED}Error: systemd configuration reload failed.${NC}"
    exit 1
fi

# Enable and start service
echo "Starting system service..."
if ! systemctl enable --now easytier.service; then
    echo -e "${RED}Error: Service start failed.${NC}"
    journalctl -u easytier.service -n 50 --no-pager
    exit 1
fi

# Verify service status
echo "Verifying service status..."
sleep 2 # Wait for service initialization
if ! systemctl is-active --quiet easytier.service; then
    echo -e "${RED}Error: Service is not running properly.${NC}"
    journalctl -u easytier.service -n 100 --no-pager
    exit 1
fi

# Post-installation checks
echo -e "${YELLOW}Verifying installation result...${NC}"
echo "Version information:"
/opt/easytier/easytier-core --version || {
    echo -e "${RED}Error: Unable to retrieve version information.${NC}"
    exit 1
}

echo -e "\n${GREEN}Installation successful! EasyTier service is running.${NC}"
echo -e "Service management commands:"
echo -e "  Start service: systemctl start easytier"
echo -e "  Stop service: systemctl stop easytier"
echo -e "  Check status: systemctl status easytier"
echo -e "  View logs: journalctl -u easytier -f"
