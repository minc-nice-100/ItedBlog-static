#!/bin/bash

# DDNS-GO
set -eu pipefail

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
        url: https://myip.ipip.net, https://ddns.oray.com/checkip, https://ip.3322.net, https://4.ipw.cn, https://v4.yinghualuo.cn/bejson
        netinterface: tun0
        cmd: ""
        domains:
            - $(cat /etc/machine-id):control-network.internal.itedev.com
      ipv6:
        enable: false
        gettype: netInterface
        url: https://speed.neu6.edu.cn/getIP.php, https://v6.ident.me, https://6.ipw.cn, https://v6.yinghualuo.cn/bejson
        netinterface: bond0
        cmd: ""
        ipv6reg: ""
        domains:
            - ""
      dns:
        name: dnspod
        id: "584970"
        secret: 4c66054ff9d531f437cde2b2bd1d6e12
      ttl: ""
user:
    username: root
    password: \$2a\$10\$Q0FwHhhx.xgVlVsiZujOk.cLpcDXemJS1An8X5XaXbEqoJhSzBoV2
webhook:
    webhookurl: ""
    webhookrequestbody: ""
    webhookheaders: ""
notallowwanaccess: true
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
# set ro permissions
chmod 444 /opt/itedev-info/internal-domain

# Success message
echo "DDNS-GO installed successfully!"