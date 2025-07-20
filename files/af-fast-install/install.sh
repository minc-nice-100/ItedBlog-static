#!/bin/bash
# Set the script to exit immediately if any command exits with a non-zero status
# and to treat errors in a pipeline as the return value of the last command in the pipeline
set -eo pipefail

# Define the URL for the installation package
INSTALL_PKG_URL="https://static.itedev.com/files/af-fast-install/package.tar.gz"
# Define the target directory for extracting the package
TARGET_DIR="package"
# Define the directory for storing information related to the installation
INFO_DIR="/opt/itedev-info/"

# Check if the script is being run as root
if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root"
    exit 1
fi

# Create the info directory if it does not already exist
if [ ! -d "$INFO_DIR" ]; then
    echo "Creating info directory at $INFO_DIR"
    mkdir -p "$INFO_DIR"
fi

# Define a cleanup function to remove temporary files
cleanup() {
    echo "Cleaning up temporary files..."
    rm -rf package.tar.gz "$TARGET_DIR" 2>/dev/null || true
}
# Set the cleanup function to be called when the script exits
trap cleanup EXIT

# Download the installation package from the defined URL
echo "Downloading installation package..."
if ! wget -q --show-progress "$INSTALL_PKG_URL"; then
    echo "Error: Failed to download the installation package"
    exit 1
fi

# Extract the downloaded package into the target directory
echo "Extracting files..."
mkdir -p "$TARGET_DIR"
if ! tar -zxvf package.tar.gz -C "$TARGET_DIR"; then
    echo "Error: Extraction failed"
    exit 1
fi

# Change the current directory to the target directory
cd "$TARGET_DIR" || exit 1

# Set execution permissions for all shell scripts in the installer directory
echo "Setting permissions..."
find installer/ -type f -name "*.sh" -exec chmod +x {} +

# Execute the installation scripts
echo "Installing dependencies..."
./installer/dependence.sh
echo "Installing easytier..."
./installer/easytier.sh
echo "Installing ddns-go..."
./installer/ddns-go.sh
echo "Installing beszel agent..."
# Download and execute the beszel agent installation script
curl -sL https://get.beszel.dev -o /tmp/install-agent.sh && chmod +x /tmp/install-agent.sh && /tmp/install-agent.sh -p 45876 -k "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAnKR+p5h6rehBbitM9bD/c2NOUbMdIqu4zRAjid8zX4" --china-mirrors

# Clean up the installation package
echo "Cleaning up installation package..."
cleanup

# Indicate that the installation has completed successfully
echo "Installation completed successfully!"

# Print the control network domain from the info directory
echo "Control network domain: $(cat /opt/itedev-info/internal-domain)"

# Indicate that the script execution has finished
echo "Script execution finished."
exit 0

