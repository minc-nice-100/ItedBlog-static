#!/bin/bash
set -eo pipefail

INSTALL_PKG_URL="https://static.itedev.com/files/af-fast-install/package.tar.gz"
TARGET_DIR="package"

# Check if root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Preparation
echo "Preparing for installation..."
mkdir -p /opt/itedev-info/

# Clean up old files
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf package.tar.gz "$TARGET_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Download installation package
echo "Downloading installation package..."
if ! wget -q --show-progress "$INSTALL_PKG_URL"; then
    echo "Error: Failed to download the installation package"
    exit 1
fi

# Extract package
echo "Extracting files..."
if ! tar -zxvf package.tar.gz -C "$TARGET_DIR"; then
    echo "Error: Extraction failed"
    exit 1
fi

# Enter installation directory
cd "$TARGET_DIR" || exit 1

# Set execution permissions
echo "Setting permissions..."
find installer/ -type f -name "*.sh" -exec chmod +x {} +

# Execute installation
echo "Installing dependencies..."
./installer/dependence.sh
echo "Installing easytier..."
./installer/easytier.sh
echo "Installing ddns-go..."
./installer/ddns-go.sh
echo "Installing beszel agent..."
curl -sL https://get.beszel.dev -o /tmp/install-agent.sh && chmod +x /tmp/install-agent.sh && /tmp/install-agent.sh -p 45876 -k "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAnKR+p5h6rehBbitM9bD/c2NOUbMdIqu4zRAjid8zX4" --china-mirrors

# Clean up installation package
echo "Cleaning up installation package..."
rm -rf package.tar.gz "$TARGET_DIR"

echo "Installation completed successfully!"

# Print the control network domain
echo "Control network domain: $(cat /opt/itedev-info/internal-domain)"

# End of script
echo "Script execution finished."
exit 0