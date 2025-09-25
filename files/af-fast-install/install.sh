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

# Parse command-line arguments
TOKEN=""
while getopts ":t:" opt; do
  case ${opt} in
    t )
      TOKEN="$OPTARG"
      ;;
    \? )
      echo "Usage: $0 [-t target]" >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

if [ -z "$TOKEN" ]; then
  echo "Error: -t parameter is required"
  exit 1
fi


# Create the info directory if it does not already exist
if [ ! -d "$INFO_DIR" ]; then
    echo "Creating info directory at $INFO_DIR"
    mkdir -p "$INFO_DIR"
fi

# Define a comprehensive cleanup function to remove temporary files
cleanup() {
    local exit_code=$?
    echo "Cleaning up temporary files..."
    
    # Remove downloaded package
    if [ -f "package.tar.gz" ]; then
        echo "Removing package.tar.gz..."
        rm -f package.tar.gz 2>/dev/null || true
    fi
    
    # Remove extracted directory
    if [ -d "$TARGET_DIR" ]; then
        echo "Removing $TARGET_DIR directory..."
        rm -rf "$TARGET_DIR" 2>/dev/null || true
    fi
    
    # Remove temporary beszel agent installation script
    if [ -f "/tmp/install-agent.sh" ]; then
        echo "Removing temporary beszel agent script..."
        rm -f /tmp/install-agent.sh 2>/dev/null || true
    fi
    
    # Clean up any other temporary files that might have been created
    echo "Cleaning up other temporary files..."
    rm -f /tmp/beszel-* 2>/dev/null || true
    rm -f /tmp/easytier-* 2>/dev/null || true
    rm -f /tmp/ddns-go-* 2>/dev/null || true
    
    # If exit code is not 0, it means the script exited due to an error
    if [ $exit_code -ne 0 ]; then
        echo "Script exited with error code $exit_code. Cleanup completed."
    else
        echo "Cleanup completed successfully."
    fi
}

# Set the cleanup function to be called when the script exits for any reason
# This includes normal exit, errors, interrupts (Ctrl+C), and other signals
trap cleanup EXIT
trap cleanup INT
trap cleanup TERM
trap cleanup HUP
trap cleanup QUIT

# Download the installation package from the defined URL
echo "Downloading installation package..."
if ! wget -q --show-progress "$INSTALL_PKG_URL"; then
    echo "Error: Failed to download the installation package"
    exit 1
fi

# Verify the downloaded file exists and is not empty
if [ ! -s "package.tar.gz" ]; then
    echo "Error: Downloaded package is empty or corrupted"
    exit 1
fi

# Extract the downloaded package into the target directory
echo "Extracting files..."
mkdir -p "$TARGET_DIR"
if ! tar -zxvf package.tar.gz -C "$TARGET_DIR"; then
    echo "Error: Extraction failed"
    exit 1
fi

# Verify extraction was successful
if [ ! -d "$TARGET_DIR/installer" ]; then
    echo "Error: Extraction incomplete - installer directory not found"
    exit 1
fi

# Change the current directory to the target directory
cd "$TARGET_DIR" || {
    echo "Error: Failed to change to target directory"
    exit 1
}

# Set execution permissions for all shell scripts in the installer directory
echo "Setting permissions..."
if ! find installer/ -type f -name "*.sh" -exec chmod +x {} +; then
    echo "Error: Failed to set permissions for installer scripts"
    exit 1
fi

# Execute the installation scripts with error handling
echo "Installing dependencies..."
if ! ./installer/dependence.sh; then
    echo "Error: Dependencies installation failed"
    exit 1
fi

echo "Installing easytier..."
if ! ./installer/easytier.sh; then
    echo "Error: Easytier installation failed"
    exit 1
fi

echo "Installing ddns-go..."
if ! ./installer/ddns-go.sh; then
    echo "Error: DDNS-GO installation failed"
    exit 1
fi

echo "Installing beszel agent..."
# Download and execute the beszel agent installation script with error handling
if ! curl -sL https://get.beszel.dev -o /tmp/install-agent.sh; then
    echo "Error: Failed to download beszel agent installation script"
    exit 1
fi

if ! chmod +x /tmp/install-agent.sh; then
    echo "Error: Failed to set permissions for beszel agent script"
    exit 1
fi

if ! /tmp/install-agent.sh -p 45876 -k "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAnKR+p5h6rehBbitM9bD/c2NOUbMdIqu4zRAjid8zX4" --china-mirrors --auto-update -url "http://e57ff0a24e7f4813a03786276e59755a.control-network.internal.itedev.com:8090" -t "$TOKEN"; then
    echo "Error: Beszel agent installation failed"
    exit 1
fi

# 检测网络环境
echo "Detecting network environment..."
if curl -s --connect-timeout 5 https://www.google.com > /dev/null 2>&1; then
    echo "Using international mirrors"
    UPDATE_COMMAND="/opt/beszel-agent/beszel-agent update"
else
    echo "Using China mirrors"
    UPDATE_COMMAND="/opt/beszel-agent/beszel-agent update --china-mirrors https://git.itedev.com/https://github.com/"
fi

# 根据网络环境生成run-update.sh内容
cat > /opt/beszel-agent/run-update.sh <<EOF
#!/bin/sh
$UPDATE_COMMAND
systemctl restart beszel-agent
exit 0
EOF
chmod +x /opt/beszel-agent/run-update.sh

# Indicate that the installation has completed successfully
echo "Installation completed successfully!"

# Print the control network domain from the info directory if it exists
if [ -f "/opt/itedev-info/internal-domain" ]; then
    echo "Control network domain: $(cat /opt/itedev-info/internal-domain)"
else
    echo "Warning: Control network domain file not found"
fi

# Indicate that the script execution has finished
echo "Script execution finished."

# Exit with success code (cleanup will be called automatically due to trap)
exit 0
