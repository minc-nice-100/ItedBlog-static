#!/bin/bash
set -eo pipefail
export DEBIAN_FRONTEND=noninteractive

# -------------------------------------------------------------
# Color Definitions
# -------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# -------------------------------------------------------------
# Logging Function
# -------------------------------------------------------------
log_message() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# -------------------------------------------------------------
# Root Check
# -------------------------------------------------------------
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: Please run as root.${NC}"
    exit 1
fi

# -------------------------------------------------------------
# Environment Checks
# -------------------------------------------------------------
log_message "Checking system environment..."
arch=$(uname -m)
if [ "$arch" != "x86_64" ]; then
    echo -e "${RED}Error: Only x86_64 architecture is supported.${NC}"
    exit 1
fi

required_space=100
available_space=$(df -m /opt | awk 'NR==2 {print $4}')
if [ "$available_space" -lt "$required_space" ]; then
    echo -e "${RED}Error: Insufficient /opt disk space (need ${required_space}MB).${NC}"
    exit 1
fi

# -------------------------------------------------------------
# Region Detection (Domestic / International)
# -------------------------------------------------------------
log_message "Detecting network region..."
is_domestic=false
if ! curl -m 3 -s https://www.google.com >/dev/null 2>&1; then
    is_domestic=true
    echo -e "${YELLOW}Google unreachable → assuming China mainland network.${NC}"
else
    echo -e "${GREEN}Google reachable → assuming overseas network.${NC}"
fi

# -------------------------------------------------------------
# APT Source Replacement (Docker Mirror)
# -------------------------------------------------------------
replace_docker_sources() {
    log_message "Replacing Docker APT sources with mirror.itedev.com..."
    
    local apt_files=()
    [ -f /etc/apt/sources.list ] && apt_files+=("/etc/apt/sources.list")
    apt_files+=($(ls /etc/apt/sources.list.d/*.list 2>/dev/null || true))

    if [ ${#apt_files[@]} -eq 0 ]; then
        log_message "No existing APT sources found, creating docker.list manually."
        echo "deb [arch=amd64] https://download.docker.com.mirror.itedev.com/linux/ubuntu $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    else
        for file in "${apt_files[@]}"; do
            if grep -q "download.docker.com" "$file"; then
                sed -i 's|http://download.docker.com|https://download.docker.com.mirror.itedev.com|g' "$file"
                sed -i 's|https://download.docker.com|https://download.docker.com.mirror.itedev.com|g' "$file"
                echo -e "${GREEN}Updated Docker source in:${NC} $file"
            fi
        done
    fi
}

# Apply if domestic
if [ "$is_domestic" = true ]; then
    replace_docker_sources
else
    log_message "Skipping APT source replacement (international network)."
fi

# -------------------------------------------------------------
# Install Dependencies
# -------------------------------------------------------------
log_message "Installing dependencies..."
apt update -y || { echo -e "${RED}APT update failed.${NC}"; exit 1; }
apt install -y curl wget jq git unzip zip bzip2 gzip tar htop nload tcpdump iperf3 || {
    echo -e "${RED}Dependency installation failed.${NC}"; exit 1;
}
echo -e "${GREEN}Dependencies installed successfully.${NC}"

# -------------------------------------------------------------
# Docker Installation
# -------------------------------------------------------------
log_message "Installing Docker and Docker Compose..."

if dpkg -l | grep -qw docker; then
    apt remove -y docker docker.io containerd runc
else
    echo -e "${YELLOW}No conflicting Docker packages found.${NC}"
fi

apt install -y docker.io docker-compose || {
    echo -e "${RED}Failed to install Docker.${NC}"; exit 1;
}

systemctl enable docker
echo -e "${GREEN}Docker installed successfully.${NC}"

# -------------------------------------------------------------
# Docker Configuration
# -------------------------------------------------------------
backup_existing_config() {
    if [ -f /etc/docker/daemon.json ]; then
        cp /etc/docker/daemon.json /etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)
        echo -e "${YELLOW}Backup created for existing Docker config.${NC}"
    fi
}

create_minimal_config() {
    cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "100m", "max-file": "3" },
  "storage-driver": "overlay2"
}
EOF
}

create_config_with_mirrors() {
    cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://registry.docker-cn.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ],
  "log-driver": "json-file",
  "log-opts": { "max-size": "100m", "max-file": "3" }
}
EOF
}

validate_daemon_json() {
    jq empty "$1" >/dev/null 2>&1
}

restart_docker_safely() {
    log_message "Restarting Docker service..."
    systemctl daemon-reload
    systemctl stop docker
    pkill -f dockerd 2>/dev/null || true
    systemctl start docker
    for i in {1..20}; do
        docker info >/dev/null 2>&1 && { echo -e "${GREEN}Docker restarted.${NC}"; return 0; }
        sleep 1
    done
    echo -e "${RED}Docker failed to start.${NC}"
    return 1
}

log_message "Configuring Docker..."
mkdir -p /etc/docker
backup_existing_config

if [ "$is_domestic" = true ]; then
    create_config_with_mirrors
else
    create_minimal_config
fi

if validate_daemon_json /etc/docker/daemon.json; then
    restart_docker_safely
else
    echo -e "${RED}Invalid daemon.json, reverting.${NC}"
    mv /etc/docker/daemon.json /etc/docker/daemon.json.invalid
    restart_docker_safely
fi

# -------------------------------------------------------------
# Verify Docker
# -------------------------------------------------------------
log_message "Verifying Docker..."
if docker version >/dev/null 2>&1; then
    echo -e "${GREEN}Docker is working correctly.${NC}"
else
    echo -e "${RED}Docker verification failed.${NC}"
    systemctl status docker --no-pager
    exit 1
fi

# -------------------------------------------------------------
# Install Portainer Agent
# -------------------------------------------------------------
log_message "Installing Portainer Agent..."
docker rm -f portainer_agent >/dev/null 2>&1 || true

if docker pull portainer/agent:2.21.4 >/dev/null 2>&1 || docker pull portainer/agent:latest >/dev/null 2>&1; then
    docker run -d \
        -p 12512:9001 \
        --name portainer_agent \
        --restart=always \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v /var/lib/docker/volumes:/var/lib/docker/volumes \
        -v /:/host \
        portainer/agent:latest
    echo -e "${GREEN}Portainer Agent running at:${NC} http://$(hostname -I | awk '{print $1}'):12512"
else
    echo -e "${YELLOW}Failed to pull Portainer Agent image.${NC}"
fi

# -------------------------------------------------------------
# Summary
# -------------------------------------------------------------
log_message "Installation Summary:"
docker --version
docker-compose --version
systemctl is-active docker && echo -e "${GREEN}Docker service active.${NC}"

if [ -f /etc/docker/daemon.json ]; then
    echo -e "${GREEN}Active Docker configuration:${NC}"
    cat /etc/docker/daemon.json
fi

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
apt autoremove -y >/dev/null 2>&1
apt autoclean >/dev/null 2>&1
echo -e "${GREEN}All done!${NC}"
