# ChatVSP Azure Deployment Guide

This directory contains automated deployment scripts for deploying ChatVSP on Microsoft Azure.

## Overview

These scripts will:
1. Create an Azure VM with all necessary infrastructure
2. Install Docker, Docker Compose, and dependencies
3. Configure environment variables with secure defaults
4. Deploy the full ChatVSP stack with SSL certificates
5. Set up monitoring and backup procedures

## Prerequisites

### On Your Local Machine:
- Azure CLI installed and configured
- Azure subscription with appropriate permissions
- SSH client
- Git

### Azure Account:
- Active subscription (you're logged in as: trey@prosourceit.ai)
- Ability to create VMs, networking resources, and storage

### Domain Configuration:
- Domain name: `chat.prosourceit.ai`
- Access to DNS provider to configure A records

## Deployment Configuration

**Infrastructure:**
- VM Size: Standard_D4s_v3 (4 vCPU, 16 GB RAM)
- Storage: 500 GB Premium SSD
- OS: Ubuntu Server 20.04 LTS
- Location: East US
- Authentication: SSH key-based

**Application:**
- Domain: https://chat.prosourceit.ai
- Authentication: Basic (email/password)
- Email domain restriction: @prosourceit.ai
- SSL: Let's Encrypt (automatic)

**Estimated Costs:**
- VM: ~$140-175/month
- Storage: ~$75/month
- Bandwidth: Variable
- **Total: ~$220-260/month**

## Quick Start

### Step 1: Deploy Azure VM (Run on Your Local Machine)

```bash
# Navigate to deployment directory
cd deployment/azure

# Make scripts executable
chmod +x *.sh

# Run VM deployment script
./deploy-vm.sh
```

This will:
- Create resource group, VNet, subnet, NSG
- Configure firewall rules for SSH, HTTP, HTTPS
- Create public IP address
- Deploy Ubuntu 20.04 VM with 500GB disk
- Output VM connection details

**Expected time:** 5-10 minutes

### Step 2: Configure DNS

While the VM is being created, configure your DNS:

```
A Record: chat.prosourceit.ai -> [VM Public IP from Step 1]
```

Verify DNS propagation:
```bash
nslookup chat.prosourceit.ai
```

**Expected time:** 2-10 minutes

### Step 3: Initialize VM (Run on Azure VM)

Connect to your VM:
```bash
ssh azureuser@[VM-PUBLIC-IP]
```

Copy deployment scripts to VM:
```bash
# On your local machine
scp deployment/azure/*.sh azureuser@[VM-PUBLIC-IP]:~/
```

On the VM, run setup:
```bash
chmod +x *.sh
./setup-vm.sh
```

This will:
- Install Docker and Docker Compose
- Install Git and dependencies
- Clone ChatVSP repository
- Configure Docker permissions

**IMPORTANT:** You must log out and back in after this step for Docker permissions to take effect.

```bash
exit
ssh azureuser@[VM-PUBLIC-IP]
```

**Expected time:** 5-7 minutes

### Step 4: Configure Environment (Run on Azure VM)

```bash
cd ~/chatvsp/deployment/azure
./configure-env.sh
```

This will:
- Generate secure encryption keys and passwords
- Create `.env` file with application settings
- Create `.env.nginx` file for SSL setup
- Save secrets to `~/.chatvsp_secrets`

**Optional:** Edit `.env` to add LLM API keys:
```bash
cd ~/chatvsp/deployment/docker_compose
vim .env
```

Add your API keys:
```bash
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...
```

**Expected time:** 2-3 minutes

### Step 5: Deploy Application (Run on Azure VM)

```bash
cd ~/chatvsp/deployment/azure
./deploy-app.sh
```

This will:
- Pull Docker images (~10-15 minutes)
- Set up SSL certificates with Let's Encrypt
- Start all services (PostgreSQL, Vespa, Redis, MinIO, API, Web, etc.)
- Run health checks

**Expected time:** 15-20 minutes

### Step 6: Create Admin Account

1. Navigate to: https://chat.prosourceit.ai/auth/signup
2. Sign up with your @prosourceit.ai email address
3. **The first user created automatically becomes admin**

### Step 7: Configure LLM Providers

1. Log in as admin
2. Go to: Admin Settings > LLM Configuration
3. Add API keys for:
   - OpenAI (for GPT-4, GPT-3.5-turbo)
   - Anthropic (for Claude models)
   - Google (for Gemini)
   - Or configure local models via Ollama/vLLM

## Deployment Scripts Reference

### `deploy-vm.sh`
Creates Azure VM infrastructure. Run on your local machine.

**What it does:**
- Creates resource group: `chatvsp-rg`
- Creates VNet and subnet
- Creates Network Security Group with firewall rules
- Creates public IP address
- Deploys Standard_D4s_v3 VM with Ubuntu 20.04
- Outputs connection details to `vm-info.txt`

**Usage:**
```bash
./deploy-vm.sh
```

### `setup-vm.sh`
Initializes VM with required software. Run on Azure VM.

**What it does:**
- Installs Docker and Docker Compose
- Installs Git, curl, vim, jq
- Clones ChatVSP repository from GitHub
- Configures Docker group permissions
- Creates helpful `NEXT_STEPS.txt` file

**Usage:**
```bash
./setup-vm.sh
# Then log out and back in
```

### `configure-env.sh`
Generates environment configuration. Run on Azure VM.

**What it does:**
- Generates secure random passwords and encryption keys
- Creates `.env` with all application settings
- Creates `.env.nginx` for SSL configuration
- Saves secrets to `~/.chatvsp_secrets` (secure backup)

**Usage:**
```bash
./configure-env.sh
# Optionally edit .env to add API keys
```

### `deploy-app.sh`
Deploys ChatVSP application. Run on Azure VM.

**What it does:**
- Verifies DNS configuration
- Pulls Docker images
- Sets up Let's Encrypt SSL certificates
- Starts all Docker services
- Runs health checks
- Creates `DEPLOYMENT_INFO.txt` with management commands

**Usage:**
```bash
./deploy-app.sh
```

## Managing Your Deployment

### Viewing Logs

```bash
cd ~/chatvsp/deployment/docker_compose

# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f api_server
docker-compose logs -f web_server
docker-compose logs -f nginx
```

### Checking Status

```bash
# Container status
docker-compose ps

# Resource usage
docker stats

# Disk usage (CRITICAL - Vespa stops at 75%)
df -h
```

### Restarting Services

```bash
cd ~/chatvsp/deployment/docker_compose

# Restart all services
docker-compose -f docker-compose.prod.yml restart

# Restart specific service
docker-compose restart api_server

# Stop all services
docker-compose -f docker-compose.prod.yml down

# Start all services
docker-compose -f docker-compose.prod.yml up -d
```

### Updating ChatVSP

```bash
cd ~/chatvsp

# Pull latest code
git pull

# Pull latest Docker images
cd deployment/docker_compose
docker-compose -f docker-compose.prod.yml pull

# Restart with new images
docker-compose -f docker-compose.prod.yml up -d
```

### Backing Up Data

**Database Backup:**
```bash
# Create backup
docker exec chatvsp-relational_db-1 pg_dump -U postgres > backup-$(date +%Y%m%d).sql

# Restore backup
cat backup-20250104.sql | docker exec -i chatvsp-relational_db-1 psql -U postgres
```

**Full Volume Backup:**
```bash
# List volumes
docker volume ls

# Backup a volume
docker run --rm -v chatvsp_db_volume:/data -v $(pwd):/backup ubuntu tar czf /backup/db_backup.tar.gz /data
```

**Recommended:** Set up automated backups using Azure Backup for VM snapshots.

## Monitoring and Maintenance

### Important Metrics to Monitor

1. **Disk Usage (CRITICAL)**
   - Vespa stops accepting writes at 75% disk usage
   - Monitor with: `df -h`
   - Set up alerts in Azure Monitor

2. **Memory Usage**
   - Check with: `docker stats`
   - Each service has memory limits in docker-compose.yml

3. **Container Health**
   - Check with: `docker-compose ps`
   - Look for containers in "restarting" or "unhealthy" state

4. **API Response Times**
   - Monitor application logs
   - Check nginx access logs: `docker-compose logs nginx`

### Setting Up Azure Monitor

1. Enable Azure Monitor for VMs in Azure Portal
2. Configure alerts for:
   - Disk usage > 70%
   - CPU usage > 80%
   - Memory usage > 90%
   - Container restart events

### Regular Maintenance Tasks

**Daily:**
- Check disk usage: `df -h`
- Verify all containers running: `docker-compose ps`

**Weekly:**
- Review application logs for errors
- Check for security updates: `sudo apt update && sudo apt upgrade`
- Verify backup integrity

**Monthly:**
- Review and rotate logs
- Check for ChatVSP updates
- Review usage metrics and costs

## Troubleshooting

### SSL Certificate Issues

**Problem:** Let's Encrypt validation fails

**Solutions:**
1. Verify DNS is configured correctly:
   ```bash
   nslookup chat.prosourceit.ai
   ```

2. Verify ports 80 and 443 are accessible:
   ```bash
   curl -I http://chat.prosourceit.ai
   curl -I https://chat.prosourceit.ai
   ```

3. Check Azure NSG rules allow traffic on ports 80 and 443

4. Check nginx logs:
   ```bash
   docker-compose logs nginx
   ```

**Rate Limit:** If you hit Let's Encrypt rate limits (5 failures per 72 hours):
- Wait 72 hours before retrying
- OR use a different domain/subdomain
- OR use Let's Encrypt staging mode (edit `.env.nginx`, set `STAGING=1`)

### Container Restart Loops

**Problem:** Containers keep restarting

**Diagnosis:**
```bash
# Check container status
docker-compose ps

# View logs for failing container
docker-compose logs [container-name]

# Check resource usage
docker stats
```

**Common Causes:**
1. Out of memory - increase VM size or reduce worker concurrency
2. Port conflicts - ensure no other services on same ports
3. Configuration errors - check `.env` file
4. Database connection issues - ensure PostgreSQL is running

### Application Not Accessible

**Problem:** Cannot access https://chat.prosourceit.ai

**Checklist:**
1. ✓ DNS configured and propagated
2. ✓ Azure NSG allows ports 80 and 443
3. ✓ Nginx container is running
4. ✓ SSL certificates are valid
5. ✓ API server is running and healthy

**Debug Steps:**
```bash
# Test local connectivity on VM
curl http://localhost
curl https://localhost

# Check nginx status
docker-compose ps nginx
docker-compose logs nginx

# Check API server
docker-compose logs api_server
```

### Out of Disk Space

**Problem:** Disk usage at capacity

**Immediate Actions:**
```bash
# Remove unused Docker images
docker image prune -a

# Remove unused volumes
docker volume prune

# Clean up old logs
docker-compose logs --tail=0 > /dev/null
```

**Long-term Solutions:**
1. Resize VM disk in Azure Portal
2. Implement log rotation
3. Clean up old document indexes
4. Consider Azure managed storage

## Security Best Practices

1. **SSH Access:**
   - Use SSH keys (not passwords)
   - Restrict SSH access in NSG to your IP range
   - Consider Azure Bastion for secure access

2. **Secrets Management:**
   - Never commit `.env` files to Git
   - Rotate passwords regularly
   - Consider Azure Key Vault for secrets

3. **Network Security:**
   - Keep NSG rules minimal (only 22, 80, 443)
   - Consider Azure Firewall for advanced filtering
   - Enable DDoS protection

4. **Updates:**
   - Keep OS updated: `sudo apt update && sudo apt upgrade`
   - Update Docker images regularly
   - Monitor CVEs for used software

5. **Backups:**
   - Enable Azure Backup for VM
   - Backup database daily
   - Test restore procedures monthly

## Cost Optimization

1. **Use Reserved Instances:** Save 40-60% with 1-3 year commitment
2. **Right-size VM:** Monitor usage and adjust if over-provisioned
3. **Use Azure Hybrid Benefit:** If you have Windows Server licenses
4. **Auto-shutdown:** Configure VM to shutdown during non-business hours
5. **Monitor Bandwidth:** Minimize data egress costs

## Support and Documentation

- **ChatVSP GitHub:** https://github.com/TreyBros/CHATVSPv2
- **Onyx Documentation:** https://docs.onyx.app
- **Azure Documentation:** https://docs.microsoft.com/azure
- **Docker Documentation:** https://docs.docker.com

## Files Created During Deployment

**On Local Machine:**
- `vm-info.txt` - VM connection details

**On Azure VM:**
- `~/NEXT_STEPS.txt` - Reminder of next steps after setup
- `~/DEPLOYMENT_INFO.txt` - Deployment summary and commands
- `~/.chatvsp_secrets` - Backup of generated passwords (secure, 600 permissions)
- `~/chatvsp/` - Application repository
- `~/chatvsp/deployment/docker_compose/.env` - Application configuration
- `~/chatvsp/deployment/docker_compose/.env.nginx` - Nginx/SSL configuration

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Azure Cloud                         │
│                                                          │
│  ┌────────────────────────────────────────────────────┐ │
│  │              Resource Group: chatvsp-rg            │ │
│  │                                                     │ │
│  │  ┌──────────────────────────────────────────────┐ │ │
│  │  │        Virtual Network: chatvsp-vnet         │ │ │
│  │  │                                               │ │ │
│  │  │  ┌─────────────────────────────────────────┐ │ │ │
│  │  │  │        Standard_D4s_v3 VM               │ │ │ │
│  │  │  │        (4 vCPU, 16 GB RAM)              │ │ │ │
│  │  │  │                                          │ │ │ │
│  │  │  │  ┌───────────────────────────────────┐  │ │ │ │
│  │  │  │  │      Docker Compose Stack         │  │ │ │ │
│  │  │  │  │                                    │  │ │ │ │
│  │  │  │  │  • nginx (reverse proxy + SSL)    │  │ │ │ │
│  │  │  │  │  • web_server (Next.js)           │  │ │ │ │
│  │  │  │  │  • api_server (FastAPI)           │  │ │ │ │
│  │  │  │  │  • background (Celery workers)    │  │ │ │ │
│  │  │  │  │  • relational_db (PostgreSQL)     │  │ │ │ │
│  │  │  │  │  • index (Vespa search)           │  │ │ │ │
│  │  │  │  │  • cache (Redis)                  │  │ │ │ │
│  │  │  │  │  • minio (S3 storage)             │  │ │ │ │
│  │  │  │  │  • inference_model_server         │  │ │ │ │
│  │  │  │  │  • indexing_model_server          │  │ │ │ │
│  │  │  │  └───────────────────────────────────┘  │ │ │ │
│  │  │  └─────────────────────────────────────────┘ │ │ │
│  │  │                                               │ │ │
│  │  └───────────────────────────────────────────────┘ │ │
│  │                                                     │ │
│  │  Public IP: chat.prosourceit.ai                    │ │
│  │  NSG: Allow 22, 80, 443                            │ │
│  └────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Next Steps After Deployment

1. **Configure LLM Providers** - Required for AI features
2. **Set up Connectors** - Pull data from Google Drive, Confluence, etc.
3. **Customize Branding** - Update colors, logos (already done for ChatVSP!)
4. **Create User Accounts** - Invite team members
5. **Set Usage Limits** - Configure quotas and rate limits
6. **Monitor Performance** - Set up Azure Monitor alerts
7. **Test Backup/Restore** - Verify your backup procedures work

## Getting Help

If you encounter issues:

1. Check logs: `docker-compose logs -f`
2. Verify DNS: `nslookup chat.prosourceit.ai`
3. Check firewall: Azure Portal > NSG rules
4. Review this README's troubleshooting section
5. Check Onyx documentation: https://docs.onyx.app

---

**Deployment created:** $(date)
**Version:** ChatVSP v1.0 (based on Onyx)
