#!/bin/bash
set -eo pipefail

INSTALL_PKG_URL="https://static.itedev.com/files/af-fast-install/package.tar.gz"
TARGET_DIR="package"

# Clean up old files
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf package.tar.gz "$TARGET_DIR"
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
if ! tar -zxvf package.tar.gz; then
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

echo "Installation completed successfully!"
