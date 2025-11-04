#!/bin/bash

################################################################################
# ChatVSP VM Setup Script
#
# This script prepares the Azure VM for running ChatVSP by installing:
# - Docker and Docker Compose
# - Git
# - Other required dependencies
#
# This script should be run ON the Azure VM after initial provisioning.
#
# Usage: ./setup-vm.sh
################################################################################

set -e

echo "================================"
echo "ChatVSP VM Setup"
echo "================================"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Please do not run this script as root/sudo."
    echo "The script will prompt for sudo when needed."
    exit 1
fi

echo "[1/6] Updating package list..."
sudo apt-get update

echo ""
echo "[2/6] Installing Docker..."
# Remove old Docker versions if present
sudo apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

# Install Docker
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
sudo usermod -aG docker $USER

echo "Docker installed successfully!"
docker --version

echo ""
echo "[3/6] Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "Docker Compose installed successfully!"
docker-compose --version

echo ""
echo "[4/6] Installing Git and other dependencies..."
sudo apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    jq \
    vim

echo ""
echo "[5/6] Cloning ChatVSP repository..."
if [ -d "$HOME/chatvsp" ]; then
    echo "Repository directory already exists. Pulling latest changes..."
    cd $HOME/chatvsp
    git pull
else
    echo "Cloning from GitHub..."
    cd $HOME
    git clone https://github.com/TreyBros/CHATVSPv2.git chatvsp
fi

cd $HOME/chatvsp
echo "Repository cloned to: $(pwd)"

echo ""
echo "[6/6] Verifying installation..."
echo ""
echo "Docker version:"
docker --version
echo ""
echo "Docker Compose version:"
docker-compose --version
echo ""
echo "Git version:"
git --version

echo ""
echo "================================"
echo "Setup Complete!"
echo "================================"
echo ""
echo "IMPORTANT: You need to log out and log back in for Docker"
echo "           permissions to take effect."
echo ""
echo "After logging back in, run:"
echo "  cd ~/chatvsp/deployment/azure"
echo "  ./configure-env.sh"
echo ""
echo "Then configure your environment and deploy the application with:"
echo "  ./deploy-app.sh"
echo ""

# Create a helpful reminder file
cat > $HOME/NEXT_STEPS.txt <<EOF
ChatVSP Setup - Next Steps
==========================

1. Log out and back in to apply Docker permissions:
   exit
   ssh $USER@$(hostname -I | awk '{print $1}')

2. Navigate to deployment directory:
   cd ~/chatvsp/deployment/azure

3. Configure environment variables:
   ./configure-env.sh

4. Deploy the application:
   ./deploy-app.sh

5. After deployment completes, create your admin account at:
   https://chat.prosourceit.ai/auth/signup

Notes:
- First user created automatically becomes admin
- Use your @prosourceit.ai email address
- SSL certificates will be automatically obtained from Let's Encrypt
- Monitor deployment: docker-compose logs -f

Repository location: $HOME/chatvsp
EOF

echo "Instructions saved to: $HOME/NEXT_STEPS.txt"
echo ""
echo "Log out now? (y/n)"
read -p "> " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Logging out..."
    sleep 2
    kill -HUP $PPID
fi
