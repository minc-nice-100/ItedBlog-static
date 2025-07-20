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

# Install dependencies
echo -e "${GREEN}Installing dependencies...${NC}"
if ! apt update -y; then
    echo -e "${RED}Error: Failed to update package lists.${NC}"
    exit 1
fi

if ! apt install -y curl wget jq git unzip zip bzip2 gzip tar iperf3 tcpdump nload htop; then
    echo -e "${RED}Error: Failed to install dependencies.${NC}"
    exit 1
fi

echo -e "${GREEN}Dependencies installed successfully.${NC}"

# Install Docker and Docker Compose
echo -e "${GREEN}Installing Docker and Docker Compose...${NC}"

# Check if Docker is installed and remove it
if dpkg -l | grep -qw docker; then
    if ! apt remove -y docker docker.io containerd runc; then
        echo -e "${RED}Error: Failed to remove conflicting Docker packages.${NC}"
        exit 1
    fi
else
    echo -e "${YELLOW}No conflicting Docker packages found to remove.${NC}"
fi

# Install Docker and Docker Compose
if ! apt install -y docker.io docker-compose; then
    echo -e "${RED}Error: Failed to install Docker and Docker Compose.${NC}"
    exit 1
fi

# Start Docker service
if ! systemctl enable --now docker; then
    echo -e "${RED}Error: Failed to enable and start Docker service.${NC}"
    exit 1
fi

echo -e "${GREEN}Docker and Docker Compose installed and started successfully.${NC}"

# Configure Docker registry mirror and log rotation
echo -e "${GREEN}Configuring Docker registry mirror and log rotation...${NC}"
if ping -c 1 -W 1 google.com &> /dev/null; then
    echo -e "${YELLOW}Google is reachable, skipping Docker registry mirror configuration.${NC}"
else
    echo -e "${GREEN}Configuring Docker registry mirror...${NC}"
    mkdir -p /etc/docker || {
        echo -e "${RED}Error: Failed to create /etc/docker directory.${NC}"
        exit 1
    }

    cat > /etc/docker/daemon.json << EOF || {
        echo -e "${RED}Error: Failed to create daemon.json file.${NC}"
        exit 1
    }
{
  "registry-mirrors": ["https://docker.m.daocloud.io"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  }
}
EOF

    # Restart Docker service
    if ! systemctl daemon-reload; then
        echo -e "${RED}Error: Failed to reload systemd configuration.${NC}"
        exit 1
    fi

    if ! systemctl restart docker; then
        echo -e "${RED}Error: Failed to restart Docker service.${NC}"
        exit 1
    fi

    echo -e "${GREEN}Docker registry mirror configured successfully.${NC}"
fi

# Install Portainer Agent
echo -e "${GREEN}Installing Portainer Agent...${NC}"
if ! docker run -d \
  -p 12512:9001 \
  --name portainer_agent \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  -v /:/host \
  portainer/agent:2.21.4; then
    echo -e "${RED}Error: Failed to install Portainer Agent.${NC}"
    exit 1
fi

echo -e "${GREEN}Portainer agent running on port 12512.${NC}"

echo -e "${GREEN}All dependencies have been installed successfully.${NC}"