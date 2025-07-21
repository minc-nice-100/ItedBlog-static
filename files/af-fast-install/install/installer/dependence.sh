#!/bin/bash

# Predefined color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the absolute path of the script
script_dir=$(dirname "$(readlink -f "$0")")

# Function to log messages
log_message() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Function to validate daemon.json
validate_daemon_json() {
    local config_file="$1"
    if [ ! -f "$config_file" ]; then
        echo -e "${RED}Error: Configuration file $config_file does not exist.${NC}"
        return 1
    fi
    
    # Check JSON syntax
    if ! jq empty "$config_file" 2>/dev/null; then
        echo -e "${RED}Error: Invalid JSON syntax in $config_file${NC}"
        echo -e "${RED}Content of the file:${NC}"
        cat "$config_file"
        return 1
    fi
    
    echo -e "${GREEN}JSON configuration is valid.${NC}"
    return 0
}

# Function to test Docker daemon configuration
test_docker_config() {
    log_message "Testing Docker daemon configuration..."
    
    # Stop Docker service
    systemctl stop docker
    
    # Test configuration
    if dockerd --config-file /etc/docker/daemon.json --validate 2>/dev/null; then
        echo -e "${GREEN}Docker daemon configuration is valid.${NC}"
        systemctl start docker
        return 0
    else
        echo -e "${RED}Docker daemon configuration validation failed.${NC}"
        echo -e "${YELLOW}Checking configuration with detailed output...${NC}"
        dockerd --config-file /etc/docker/daemon.json --validate
        systemctl start docker
        return 1
    fi
}

# Function to create backup of existing configuration
backup_existing_config() {
    if [ -f /etc/docker/daemon.json ]; then
        local backup_file="/etc/docker/daemon.json.backup.$(date +%Y%m%d_%H%M%S)"
        cp /etc/docker/daemon.json "$backup_file"
        echo -e "${YELLOW}Existing configuration backed up to: $backup_file${NC}"
    fi
}

# Function to create minimal Docker configuration
create_minimal_config() {
    log_message "Creating minimal Docker configuration..."
    
    cat > /etc/docker/daemon.json << 'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2"
}
EOF
}

# Function to create Docker configuration with mirrors
create_config_with_mirrors() {
    log_message "Creating Docker configuration with registry mirrors..."
    
    cat > /etc/docker/daemon.json << 'EOF'
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io",
    "https://registry.docker-cn.com",
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com"
  ],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5
}
EOF
}

# Function to safely restart Docker
restart_docker_safely() {
    log_message "Restarting Docker service safely..."
    
    # Reload systemd configuration
    if ! systemctl daemon-reload; then
        echo -e "${RED}Error: Failed to reload systemd daemon.${NC}"
        return 1
    fi
    
    # Stop Docker gracefully
    systemctl stop docker
    sleep 2
    
    # Kill any remaining Docker processes
    pkill -f dockerd 2>/dev/null || true
    sleep 1
    
    # Start Docker
    if systemctl start docker; then
        # Wait for Docker to be ready
        local timeout=30
        local count=0
        while [ $count -lt $timeout ]; do
            if docker info >/dev/null 2>&1; then
                echo -e "${GREEN}Docker started successfully.${NC}"
                return 0
            fi
            sleep 1
            ((count++))
        done
        
        echo -e "${RED}Docker started but is not responding within timeout.${NC}"
        return 1
    else
        echo -e "${RED}Failed to start Docker service.${NC}"
        return 1
    fi
}

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root. Please use sudo.${NC}"
    exit 1
fi

# Installation pre-check list
log_message "Performing system environment checks..."

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
log_message "Installing dependencies..."
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
log_message "Installing Docker and Docker Compose..."

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

# Start Docker service initially
if ! systemctl enable docker; then
    echo -e "${RED}Error: Failed to enable Docker service.${NC}"
    exit 1
fi

echo -e "${GREEN}Docker and Docker Compose installed successfully.${NC}"

# Configure Docker
log_message "Configuring Docker..."

# Create docker directory
mkdir -p /etc/docker

# Backup existing configuration
backup_existing_config

# Test network connectivity to determine configuration
log_message "Testing network connectivity..."
if timeout 5 ping -c 1 google.com >/dev/null 2>&1; then
    echo -e "${GREEN}Internet connectivity is good, using minimal configuration.${NC}"
    create_minimal_config
else
    echo -e "${YELLOW}Limited internet connectivity detected, adding registry mirrors.${NC}"
    create_config_with_mirrors
fi

# Validate the created configuration
if ! validate_daemon_json /etc/docker/daemon.json; then
    echo -e "${RED}Configuration validation failed, falling back to minimal config.${NC}"
    create_minimal_config
    
    if ! validate_daemon_json /etc/docker/daemon.json; then
        echo -e "${RED}Even minimal configuration failed. Removing daemon.json.${NC}"
        rm -f /etc/docker/daemon.json
    fi
fi

# Test configuration if daemon.json exists
if [ -f /etc/docker/daemon.json ]; then
    # Show the configuration
    log_message "Docker configuration created:"
    cat /etc/docker/daemon.json
    
    # Restart Docker with new configuration
    if ! restart_docker_safely; then
        echo -e "${RED}Failed to restart Docker with new configuration.${NC}"
        echo -e "${YELLOW}Reverting to default configuration...${NC}"
        
        # Move problematic config
        mv /etc/docker/daemon.json /etc/docker/daemon.json.failed 2>/dev/null
        
        # Try restarting without configuration
        if restart_docker_safely; then
            echo -e "${YELLOW}Docker restarted successfully without custom configuration.${NC}"
        else
            echo -e "${RED}Failed to start Docker even without configuration.${NC}"
            echo -e "${RED}Docker logs:${NC}"
            journalctl -u docker --no-pager -n 20
            exit 1
        fi
    fi
else
    # Start Docker without custom configuration
    if ! restart_docker_safely; then
        echo -e "${RED}Failed to start Docker.${NC}"
        echo -e "${RED}Docker logs:${NC}"
        journalctl -u docker --no-pager -n 20
        exit 1
    fi
fi

# Verify Docker is working
log_message "Verifying Docker installation..."
if ! timeout 30 docker version >/dev/null 2>&1; then
    echo -e "${RED}Docker is not responding properly.${NC}"
    systemctl status docker --no-pager
    exit 1
fi

echo -e "${GREEN}Docker is working correctly.${NC}"

# Install Portainer Agent
log_message "Installing Portainer Agent..."

# Remove existing container if it exists
docker rm -f portainer_agent 2>/dev/null || true

# Pull and run Portainer Agent
if timeout 180 docker pull portainer/agent:2.21.4; then
    PORTAINER_IMAGE="portainer/agent:2.21.4"
elif timeout 180 docker pull portainer/agent:latest; then
    PORTAINER_IMAGE="portainer/agent:latest"
else
    echo -e "${RED}Failed to pull Portainer Agent image.${NC}"
    PORTAINER_IMAGE=""
fi

if [ -n "$PORTAINER_IMAGE" ]; then
    if docker run -d \
      -p 12512:9001 \
      --name portainer_agent \
      --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v /var/lib/docker/volumes:/var/lib/docker/volumes \
      -v /:/host \
      "$PORTAINER_IMAGE"; then
        echo -e "${GREEN}Portainer Agent is running on port 12512.${NC}"
        echo -e "${GREEN}Access URL: http://$(hostname -I | awk '{print $1}'):12512${NC}"
    else
        echo -e "${RED}Failed to start Portainer Agent.${NC}"
    fi
else
    echo -e "${YELLOW}Skipping Portainer Agent installation due to network issues.${NC}"
fi

# Display final status
log_message "Installation Summary:"
echo -e "${GREEN}Docker version:${NC}"
docker --version

echo -e "${GREEN}Docker Compose version:${NC}"
docker-compose --version

echo -e "${GREEN}Docker service status:${NC}"
systemctl is-active docker

if [ -f /etc/docker/daemon.json ]; then
    echo -e "${GREEN}Active Docker configuration:${NC}"
    cat /etc/docker/daemon.json
else
    echo -e "${YELLOW}Using default Docker configuration (no daemon.json)${NC}"
fi

echo -e "${GREEN}Running containers:${NC}"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Cleanup
log_message "Cleaning up..."
apt autoremove -y >/dev/null 2>&1
apt autoclean >/dev/null 2>&1

echo -e "${GREEN}Installation completed successfully!${NC}"
