#!/bin/bash

################################################################################
# ChatVSP EC2 Setup Script
#
# This script initializes an EC2 instance with all required software for
# deploying ChatVSP using Docker Compose.
#
# Prerequisites:
# - Fresh Ubuntu EC2 instance
# - SSH access to the instance
#
# This script should be run ON the EC2 instance.
#
# Usage: ./setup-ec2.sh
################################################################################

set -e

echo "================================"
echo "ChatVSP EC2 Instance Setup"
echo "================================"
echo ""
echo "This script will install:"
echo "  - Docker and Docker Compose"
echo "  - Git and dependencies"
echo "  - ChatVSP repository"
echo ""

# Update system
echo "[1/6] Updating system packages..."
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

# Install dependencies
echo ""
echo "[2/6] Installing dependencies..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    vim \
    jq \
    htop

# Install Docker
echo ""
echo "[3/6] Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Set up Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker

    # Add current user to docker group
    sudo usermod -aG docker $USER

    echo "Docker installed successfully!"
else
    echo "Docker is already installed."
fi

# Install Docker Compose standalone (in addition to plugin)
echo ""
echo "[4/6] Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
        -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "Docker Compose installed successfully!"
else
    echo "Docker Compose is already installed."
fi

# Clone ChatVSP repository
echo ""
echo "[5/6] Cloning ChatVSP repository..."
if [ ! -d "$HOME/chatvsp" ]; then
    cd $HOME
    git clone https://github.com/TreyBros/CHATVSPv2.git chatvsp
    echo "Repository cloned to ~/chatvsp"
else
    echo "Repository already exists at ~/chatvsp"
fi

echo ""
echo "[6/6] Verifying installation..."
echo ""
echo "Docker version:"
docker --version
echo ""
echo "Docker Compose version:"
docker-compose --version
echo ""

echo "================================"
echo "Setup Complete!"
echo "================================"
echo ""
echo "IMPORTANT: You must log out and back in for Docker permissions to take effect."
echo ""
echo "Run: exit"
echo "Then: ssh ubuntu@<your-ec2-ip>"
echo ""
echo "Next steps:"
echo "  1. Log out and back in"
echo "  2. cd ~/chatvsp/deployment/aws_ec2"
echo "  3. ./configure-env.sh"
echo "  4. ./deploy-app.sh"
echo ""

# Save reminder file
cat > "$HOME/NEXT_STEPS.txt" <<EOF
ChatVSP EC2 Setup Complete
==========================

IMPORTANT: Log out and back in for Docker permissions!

Next Steps:
1. exit
2. ssh ubuntu@$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
3. cd ~/chatvsp/deployment/aws_ec2
4. ./configure-env.sh
5. ./deploy-app.sh

Repository: ~/chatvsp
Documentation: ~/chatvsp/deployment/aws_ec2/README.md
EOF

echo "Setup instructions saved to: ~/NEXT_STEPS.txt"
echo ""
