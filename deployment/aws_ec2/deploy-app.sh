#!/bin/bash

################################################################################
# ChatVSP Application Deployment Script
#
# This script deploys the ChatVSP application on Azure VM using Docker Compose.
# It handles:
# - Docker image pulling
# - SSL certificate setup via Let's Encrypt
# - Service deployment and health checks
#
# Prerequisites:
# - setup-vm.sh has been run
# - configure-env.sh has been run
# - DNS is configured and propagated
#
# This script should be run ON the Azure VM.
#
# Usage: ./deploy-app.sh
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEPLOYMENT_DIR="$REPO_ROOT/deployment/docker_compose"

echo "================================"
echo "ChatVSP Application Deployment"
echo "================================"
echo ""

# Check if running with Docker permissions
if ! docker ps > /dev/null 2>&1; then
    echo "ERROR: Cannot run Docker commands."
    echo "Did you log out and back in after running setup-vm.sh?"
    echo ""
    echo "If not, please run:"
    echo "  exit"
    echo "  ssh $(whoami)@$(hostname -I | awk '{print $1}')"
    exit 1
fi

# Check if .env exists
if [ ! -f "$DEPLOYMENT_DIR/.env" ]; then
    echo "ERROR: .env file not found at $DEPLOYMENT_DIR/.env"
    echo "Please run configure-env.sh first:"
    echo "  cd $SCRIPT_DIR"
    echo "  ./configure-env.sh"
    exit 1
fi

# Check if .env.nginx exists
if [ ! -f "$DEPLOYMENT_DIR/.env.nginx" ]; then
    echo "ERROR: .env.nginx file not found at $DEPLOYMENT_DIR/.env.nginx"
    echo "Please run configure-env.sh first:"
    echo "  cd $SCRIPT_DIR"
    echo "  ./configure-env.sh"
    exit 1
fi

cd "$DEPLOYMENT_DIR"

# Load domain from .env.nginx
source .env.nginx

echo "Configuration:"
echo "  Domain: $DOMAIN"
echo "  Deployment directory: $DEPLOYMENT_DIR"
echo ""

# Check DNS configuration
echo "[1/7] Verifying DNS configuration..."
DOMAIN_IP=$(dig +short "$DOMAIN" | head -n 1)
if [ -z "$DOMAIN_IP" ]; then
    echo "WARNING: DNS lookup for $DOMAIN failed."
    echo "Please ensure your DNS A record is configured:"
    echo "  $DOMAIN -> [Your VM Public IP]"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled. Please configure DNS and try again."
        exit 1
    fi
else
    echo "DNS resolved: $DOMAIN -> $DOMAIN_IP"
fi

echo ""
echo "[2/7] Pulling Docker images..."
echo "This may take 10-15 minutes depending on connection speed..."
docker-compose -f docker-compose.prod.yml pull

echo ""
echo "[3/7] Creating Docker volumes..."
docker-compose -f docker-compose.prod.yml up --no-start

echo ""
echo "[4/7] Setting up SSL certificates with Let's Encrypt..."
echo ""
echo "IMPORTANT: Let's Encrypt has rate limits:"
echo "  - 5 failed validation attempts per 72 hours"
echo "  - If you exceed this, you must wait or use a different domain"
echo ""
echo "Make sure:"
echo "  ✓ DNS is configured correctly: $DOMAIN -> $DOMAIN_IP"
echo "  ✓ Ports 80 and 443 are open in Azure NSG"
echo "  ✓ No other web server is running on ports 80/443"
echo ""
read -p "Continue with SSL setup? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment paused. You can manually set up SSL later."
    echo "To continue without SSL, comment out the nginx and certbot services"
    echo "in docker-compose.prod.yml and restart."
    exit 1
fi

# Run Let's Encrypt initialization script
if [ -f "$DEPLOYMENT_DIR/init-letsencrypt.sh" ]; then
    chmod +x "$DEPLOYMENT_DIR/init-letsencrypt.sh"
    "$DEPLOYMENT_DIR/init-letsencrypt.sh"
else
    echo "WARNING: init-letsencrypt.sh not found. SSL setup skipped."
    echo "You may need to set up SSL manually."
fi

echo ""
echo "[5/7] Starting ChatVSP services..."
docker-compose -f docker-compose.prod.yml up -d

echo ""
echo "[6/7] Waiting for services to initialize..."
echo "This may take 2-3 minutes..."

# Wait for API server to be healthy
MAX_ATTEMPTS=60
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if docker-compose logs api_server 2>&1 | grep -q "Application startup complete" 2>/dev/null; then
        echo "API server is ready!"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    if [ $((ATTEMPT % 10)) -eq 0 ]; then
        echo "Still waiting... ($ATTEMPT/${MAX_ATTEMPTS})"
    fi
    sleep 5
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo "WARNING: API server did not start within expected time."
    echo "Check logs with: docker-compose logs api_server"
fi

echo ""
echo "[7/7] Running health checks..."

# Check container status
echo ""
echo "Container Status:"
docker-compose ps

# Check for any containers in unhealthy state
UNHEALTHY=$(docker-compose ps | grep -c "unhealthy" || true)
if [ "$UNHEALTHY" -gt 0 ]; then
    echo ""
    echo "WARNING: Some containers are unhealthy."
    echo "Review logs with: docker-compose logs [service-name]"
fi

echo ""
echo "================================"
echo "Deployment Complete!"
echo "================================"
echo ""
echo "ChatVSP is now running at: https://$DOMAIN"
echo ""
echo "Next Steps:"
echo ""
echo "1. Create your admin account:"
echo "   Go to: https://$DOMAIN/auth/signup"
echo "   Use your @prosourceit.ai email address"
echo "   The first user created automatically becomes admin"
echo ""
echo "2. Configure LLM providers (required for AI features):"
echo "   - Log in as admin"
echo "   - Go to Admin Settings > LLM Configuration"
echo "   - Add API keys for OpenAI, Anthropic, etc."
echo ""
echo "3. Optional: Add LLM API keys to .env and restart:"
echo "   vim $DEPLOYMENT_DIR/.env"
echo "   # Add OPENAI_API_KEY, ANTHROPIC_API_KEY, etc."
echo "   docker-compose -f docker-compose.prod.yml restart"
echo ""
echo "Useful Commands:"
echo ""
echo "  View all logs:"
echo "    docker-compose logs -f"
echo ""
echo "  View specific service logs:"
echo "    docker-compose logs -f api_server"
echo "    docker-compose logs -f web_server"
echo ""
echo "  Check container status:"
echo "    docker-compose ps"
echo ""
echo "  Restart all services:"
echo "    docker-compose -f docker-compose.prod.yml restart"
echo ""
echo "  Stop all services:"
echo "    docker-compose -f docker-compose.prod.yml down"
echo ""
echo "  Update to latest version:"
echo "    git pull"
echo "    docker-compose -f docker-compose.prod.yml pull"
echo "    docker-compose -f docker-compose.prod.yml up -d"
echo ""
echo "Monitoring:"
echo "  Check disk usage (IMPORTANT - Vespa stops at 75%):"
echo "    df -h"
echo ""
echo "  Monitor Docker resource usage:"
echo "    docker stats"
echo ""
echo "Backup:"
echo "  Database backup:"
echo "    docker exec chatvsp-relational_db-1 pg_dump -U postgres > backup.sql"
echo ""

# Save deployment info
cat > "$HOME/DEPLOYMENT_INFO.txt" <<EOF
ChatVSP Deployment Information
==============================

Deployment Date: $(date)
Domain: https://$DOMAIN
Repository: $REPO_ROOT
Deployment Directory: $DEPLOYMENT_DIR

Services Running:
$(docker-compose ps)

To manage your deployment:
- Logs: docker-compose logs -f
- Status: docker-compose ps
- Restart: docker-compose -f docker-compose.prod.yml restart
- Stop: docker-compose -f docker-compose.prod.yml down

Configuration:
- Environment: $DEPLOYMENT_DIR/.env
- Nginx: $DEPLOYMENT_DIR/.env.nginx
- Secrets: $HOME/.chatvsp_secrets
EOF

echo "Deployment info saved to: $HOME/DEPLOYMENT_INFO.txt"
echo ""
