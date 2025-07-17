#!/bin/bash
# Change to script directory
cd "$(dirname "$0")" || exit 1

# Check root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Download installation package
if ! wget -q --show-progress https://static.itedev.com/files/af-fast-install/package.tar.gz; then
    echo "Error: Failed to download package"
    exit 1
fi

# Create and extract package
mkdir -p package && tar -zxf package.tar.gz -C package/ || {
    echo "Error: Failed to extract package"
    exit 1
}

# Execute installation scripts
(
    cd package || exit 1
    chmod -v +x installer/*
    ./installer/easytier.sh && ./installer/dependence.sh
) || exit 1

# Cleanup with confirmation
echo "Cleaning temporary files..."
rm -rf package/ package.tar.gz && echo "Cleanup completed"

echo "Installation finished successfully"
exit 0
