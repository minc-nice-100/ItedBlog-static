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

# Create docker directory
if ! mkdir -p /etc/docker; then
    echo -e "${RED}Error: Failed to create /etc/docker directory.${NC}"
    exit 1
fi

# Check if Google is reachable
if ping -c 1 -W 3 google.com >/dev/null 2>&1; then
    echo -e "${YELLOW}Google is reachable, configuring Docker with log rotation only.${NC}"
    
    # Create daemon.json with log rotation settings only
    cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  }
}
EOF
else
    echo -e "${GREEN}Google is not reachable, configuring Docker with registry mirror and log rotation...${NC}"
    
    # Create daemon.json file with mirror and log rotation
    cat > /etc/docker/daemon.json <<'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://registry.docker-cn.com",
    "https://docker.mirrors.ustc.edu.cn"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  }
}
EOF
fi

# Validate JSON syntax
if ! jq . /etc/docker/daemon.json >/dev/null 2>&1; then
    echo -e "${RED}Error: Invalid JSON in daemon.json file.${NC}"
    echo -e "${RED}Content of daemon.json:${NC}"
    cat /etc/docker/daemon.json
    exit 1
fi

echo -e "${GREEN}Docker configuration file created and validated successfully.${NC}"

# Restart Docker service with error handling
if ! systemctl daemon-reload; then
    echo -e "${RED}Error: Failed to reload systemd configuration.${NC}"
    exit 1
fi

# Test Docker restart
echo -e "${YELLOW}Restarting Docker service...${NC}"
if ! systemctl restart docker; then
    echo -e "${RED}Error: Failed to restart Docker service. Checking logs...${NC}"
    echo -e "${RED}Recent Docker logs:${NC}"
    journalctl -u docker --no-pager -l | tail -20
    
    # Try to recover by backing up and removing daemon.json
    echo -e "${YELLOW}Attempting to recover by removing daemon.json...${NC}"
    if [ -f /etc/docker/daemon.json ]; then
        mv /etc/docker/daemon.json /etc/docker/daemon.json.failed
        echo -e "${YELLOW}Problematic configuration backed up to /etc/docker/daemon.json.failed${NC}"
    fi
    
    # Create a minimal daemon.json with just log rotation
    echo -e "${YELLOW}Creating minimal configuration with log rotation only...${NC}"
    cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "5"
  }
}
EOF
    
    if systemctl restart docker; then
        echo -e "${YELLOW}Docker started successfully with minimal configuration (log rotation only).${NC}"
        echo -e "${YELLOW}Please check the failed configuration in /etc/docker/daemon.json.failed${NC}"
    else
        echo -e "${RED}Failed to start Docker even with minimal configuration.${NC}"
        echo -e "${RED}Docker service logs:${NC}"
        journalctl -u docker --no-pager -l | tail -30
        exit 1
    fi
else
    # Verify Docker is running and wait a moment for it to fully start
    sleep 3
    if ! systemctl is-active --quiet docker; then
        echo -e "${RED}Error: Docker service is not running after restart.${NC}"
        echo -e "${RED}Docker service status:${NC}"
        systemctl status docker --no-pager -l
        exit 1
    fi
    
    echo -e "${GREEN}Docker restarted successfully with new configuration.${NC}"
fi

# Test Docker functionality
echo -e "${YELLOW}Testing Docker functionality...${NC}"
if ! timeout 30 docker version >/dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not functioning properly or timed out.${NC}"
    echo -e "${RED}Docker service status:${NC}"
    systemctl status docker --no-pager -l
    exit 1
fi

echo -e "${GREEN}Docker configuration completed successfully.${NC}"

# Install Portainer Agent
echo -e "${GREEN}Installing Portainer Agent...${NC}"

# Pull the image first to check connectivity
echo -e "${YELLOW}Pulling Portainer Agent image...${NC}"
if ! timeout 300 docker pull portainer/agent:2.21.4; then
    echo -e "${RED}Error: Failed to pull Portainer Agent image.${NC}"
    echo -e "${YELLOW}This might be due to network connectivity issues.${NC}"
    
    # Try with different tag or registry
    echo -e "${YELLOW}Trying to pull from alternative source...${NC}"
    if ! timeout 300 docker pull portainer/agent:latest; then
        echo -e "${RED}Error: Failed to pull Portainer Agent image from alternative source.${NC}"
        echo -e "${YELLOW}Skipping Portainer Agent installation.${NC}"
    else
        # Run with latest tag
        if ! docker run -d \
          -p 12512:9001 \
          --name portainer_agent \
          --restart=always \
          -v /var/run/docker.sock:/var/run/docker.sock \
          -v /var/lib/docker/volumes:/var/lib/docker/volumes \
          -v /:/host \
          portainer/agent:latest; then
            echo -e "${RED}Error: Failed to start Portainer Agent container.${NC}"
        else
            echo -e "${GREEN}Portainer agent (latest) running on port 12512.${NC}"
        fi
    fi
else
    # Run with specified version
    if ! docker run -d \
      -p 12512:9001 \
      --name portainer_agent \
      --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v /var/lib/docker/volumes:/var/lib/docker/volumes \
      -v /:/host \
      portainer/agent:2.21.4; then
        echo -e "${RED}Error: Failed to start Portainer Agent container.${NC}"
        
        # Check if container already exists
        if docker ps -a | grep -q portainer_agent; then
            echo -e "${YELLOW}Portainer Agent container already exists. Removing and retrying...${NC}"
            docker rm -f portainer_agent 2>/dev/null
            
            if docker run -d \
              -p 12512:9001 \
              --name portainer_agent \
              --restart=always \
              -v /var/run/docker.sock:/var/run/docker.sock \
              -v /var/lib/docker/volumes:/var/lib/docker/volumes \
              -v /:/host \
              portainer/agent:2.21.4; then
                echo -e "${GREEN}Portainer agent running on port 12512.${NC}"
            else
                echo -e "${RED}Error: Failed to install Portainer Agent after retry.${NC}"
            fi
        fi
    else
        echo -e "${GREEN}Portainer agent running on port 12512.${NC}"
    fi
fi

# Verify Portainer Agent is running
if docker ps | grep -q portainer_agent; then
    echo -e "${GREEN}Portainer Agent is running successfully.${NC}"
    echo -e "${GREEN}Access URL: http://$(hostname -I | awk '{print $1}'):12512${NC}"
else
    echo -e "${YELLOW}Portainer Agent installation was skipped or failed.${NC}"
fi

echo -e "${GREEN}All dependencies have been installed successfully.${NC}"

# Display system information
echo -e "${GREEN}=== Installation Summary ===${NC}"
echo -e "${GREEN}Docker version:${NC}"
docker --version 2>/dev/null || echo -e "${RED}Docker version check failed${NC}"

echo -e "${GREEN}Docker Compose version:${NC}"
docker-compose --version 2>/dev/null || echo -e "${RED}Docker Compose version check failed${NC}"

echo -e "${GREEN}Docker service status:${NC}"
systemctl is-active docker && echo -e "${GREEN}Active${NC}" || echo -e "${RED}Inactive${NC}"

if [ -f /etc/docker/daemon.json ]; then
    echo -e "${GREEN}Docker configuration:${NC}"
    cat /etc/docker/daemon.json
fi

echo -e "${GREEN}Running containers:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo -e "${RED}No containers running or Docker not accessible${NC}"

# Cleanup temporary files
echo -e "${GREEN}Cleaning up temporary files...${NC}"
apt autoremove -y >/dev/null 2>&1
apt autoclean >/dev/null 2>&1

echo -e "${GREEN}Installation completed successfully!${NC}"
