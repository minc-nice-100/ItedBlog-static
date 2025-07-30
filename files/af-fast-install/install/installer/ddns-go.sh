#!/bin/bash

# DDNS-GO
set -eo pipefail

# Run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root"
    exit 1
fi

# Set directory to the script's location
script_dir=$(dirname "$(readlink -f "$0")")
cd "$script_dir"

# Remove old version
echo "Removing old version of DDNS-GO"
rm -rf /opt/ddns-go

# Copy files to /opt/ddns-go
echo "Copying DDNS-GO files to /opt/ddns-go"
mkdir -p /opt/ddns-go
cp -r ../ddns-go/* /opt/ddns-go/

# Set permissions
echo "Setting permissions for DDNS-GO"
chmod +x /opt/ddns-go/ddns-go

# Create config file, use the /etc/machine-id as the sub domain name
echo "Creating config file at /opt/ddns-go/config.yaml"
cat > /opt/ddns-go/config.yaml << EOF
dnsconf:
    - name: ""
      ipv4:
        enable: true
        gettype: netInterface
        netinterface: tun114514
        domains:
            - $(cat /etc/machine-id).control-network.internal:itedev.com
      dns:
        name: cloudflare
        id: "584970"
        secret: GL3_p-5nBKmqXSfejf3_8pOzI4dHVT2eFj9teUNn
      ttl: "60"
lang: zh
EOF

# Install service
echo "Installing DDNS-GO service"
/opt/ddns-go/ddns-go -s install -c /opt/ddns-go/config.yaml -noweb -cacheTimes 20 -f 1

# Create INFO file
echo "Creating INFO file at /opt/itedev-info/internal-domain"
cat > /opt/itedev-info/internal-domain << EOF
$(cat /etc/machine-id).control-network.internal.itedev.com
EOF
# Set permissions
chmod 444 /opt/itedev-info/internal-domain

# Success message
echo "DDNS-GO installed successfully!"
