#!/bin/bash

################################################################################
# ChatVSP Environment Configuration Script
#
# This script generates environment configuration files with secure defaults
# for deploying ChatVSP on Azure.
#
# This script should be run ON the Azure VM before deploying the application.
#
# Usage: ./configure-env.sh
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEPLOYMENT_DIR="$REPO_ROOT/deployment/docker_compose"

echo "================================"
echo "ChatVSP Environment Configuration"
echo "================================"
echo ""
echo "This script will create .env files with secure, randomly generated"
echo "passwords and encryption keys for your ChatVSP deployment."
echo ""

# Check if we're in the right place
if [ ! -d "$DEPLOYMENT_DIR" ]; then
    echo "ERROR: Cannot find deployment directory at $DEPLOYMENT_DIR"
    echo "Are you running this script from the correct location?"
    exit 1
fi

cd "$DEPLOYMENT_DIR"

# Function to generate secure random string
generate_secret() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

# Generate secrets
ENCRYPTION_KEY=$(generate_secret)
SESSION_SECRET=$(generate_secret)
POSTGRES_PASSWORD=$(generate_secret)
DB_READONLY_PASSWORD=$(generate_secret)
MINIO_PASSWORD=$(generate_secret)

echo "[1/3] Generating secure secrets..."
echo "  - Encryption key: [GENERATED]"
echo "  - Session secret: [GENERATED]"
echo "  - PostgreSQL password: [GENERATED]"
echo "  - MinIO password: [GENERATED]"

echo ""
echo "[2/3] Creating .env file..."

# Create the main .env file
cat > .env <<EOF
# ChatVSP Environment Configuration
# Generated on: $(date)
# Domain: chat.prosourceit.ai

################################################################################
# Core Application Settings
################################################################################

# Domain where ChatVSP will be accessible
WEB_DOMAIN=https://chat.prosourceit.ai

# Authentication method
AUTH_TYPE=basic
REQUIRE_EMAIL_VERIFICATION=false
SMTP_SERVER=
SMTP_PORT=587
SMTP_USER=
SMTP_PASS=
EMAIL_FROM=

# Restrict registration to specific email domains (comma-separated)
VALID_EMAIL_DOMAINS=prosourceit.ai

# Security
ENCRYPTION_KEY_SECRET=$ENCRYPTION_KEY
SECRET=$SESSION_SECRET
SESSION_EXPIRE_TIME_SECONDS=604800

################################################################################
# Database Configuration
################################################################################

POSTGRES_USER=postgres
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=postgres
DB_READONLY_USER=db_readonly_user
DB_READONLY_PASSWORD=$DB_READONLY_PASSWORD

################################################################################
# Storage Configuration (MinIO/S3)
################################################################################

# MinIO credentials (S3-compatible object storage)
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=$MINIO_PASSWORD

# S3 settings (use MinIO credentials)
S3_AWS_ACCESS_KEY_ID=minioadmin
S3_AWS_SECRET_ACCESS_KEY=$MINIO_PASSWORD
S3_BUCKET_NAME=chatvsp-files
MINIO_DOMAIN=http://minio:9000

################################################################################
# Model Server Configuration
################################################################################

# Inference model server settings
INFERENCE_MODEL_SERVER_HOST=inference_model_server
INFERENCE_MODEL_SERVER_PORT=9000

# Indexing model server settings
INDEXING_MODEL_SERVER_HOST=indexing_model_server
INDEXING_MODEL_SERVER_PORT=9000

################################################################################
# Search & Indexing Configuration
################################################################################

# Vespa search engine
VESPA_HOST=index
VESPA_PORT=8081

# Document processing
NUM_INDEXING_WORKERS=1
DASK_JOB_CLIENT_ENABLED=false

################################################################################
# Optional: LLM Provider API Keys
################################################################################
# Add your API keys here after deployment

# OpenAI
OPENAI_API_KEY=

# Anthropic (Claude)
ANTHROPIC_API_KEY=

# Google (Gemini)
GOOGLE_API_KEY=

# Azure OpenAI
AZURE_OPENAI_API_KEY=
AZURE_OPENAI_ENDPOINT=
AZURE_OPENAI_DEPLOYMENT_NAME=

################################################################################
# Optional: Web Search API Keys
################################################################################

# Exa (AI-powered search)
EXA_API_KEY=

# Google Programmable Search Engine
GOOGLE_PSE_API_KEY=
GOOGLE_PSE_ENGINE_ID=

################################################################################
# Performance & Scaling
################################################################################

# API server settings
API_SERVER_HOST=0.0.0.0
API_SERVER_PORT=8080

# Background worker settings
CELERY_WORKER_CONCURRENCY=1

# Nginx settings
NGINX_RESOLVER=127.0.0.11

################################################################################
# Feature Flags
################################################################################

# Enable/disable features
ENABLE_SLACK_BOT=false
ENABLE_GOOGLE_DRIVE_SYNC=true
ENABLE_WEB_SEARCH=false

################################################################################
# Logging & Monitoring
################################################################################

LOG_LEVEL=info
LOG_ALL_MODEL_INTERACTIONS=false
LOG_VESPA_TIMING_INFORMATION=false

################################################################################
# Docker Image Configuration
################################################################################

IMAGE_TAG=latest
EOF

echo "Created: .env"

echo ""
echo "[3/3] Creating .env.nginx file..."

# Create nginx environment file for Let's Encrypt
cat > .env.nginx <<EOF
# Nginx & SSL Configuration
# Generated on: $(date)

# Domain for SSL certificate
DOMAIN=chat.prosourceit.ai

# Email for Let's Encrypt notifications
EMAIL=trey@prosourceit.ai

# Let's Encrypt settings
STAGING=0
EOF

echo "Created: .env.nginx"

echo ""
echo "================================"
echo "Configuration Complete!"
echo "================================"
echo ""
echo "Configuration files created:"
echo "  - $DEPLOYMENT_DIR/.env"
echo "  - $DEPLOYMENT_DIR/.env.nginx"
echo ""
echo "IMPORTANT: Please review and update the following in .env:"
echo ""
echo "1. LLM Provider API Keys (required for AI features):"
echo "   - OPENAI_API_KEY (for GPT-4, etc.)"
echo "   - ANTHROPIC_API_KEY (for Claude)"
echo ""
echo "2. SMTP Settings (optional, for email verification):"
echo "   - SMTP_SERVER, SMTP_PORT, SMTP_USER, SMTP_PASS"
echo "   - EMAIL_FROM"
echo ""
echo "3. Web Search API Keys (optional):"
echo "   - EXA_API_KEY or GOOGLE_PSE_API_KEY"
echo ""
echo "To edit configuration:"
echo "  vim $DEPLOYMENT_DIR/.env"
echo ""
echo "After reviewing/updating, deploy the application:"
echo "  ./deploy-app.sh"
echo ""

# Save secrets to a secure location (only readable by user)
SECRETS_FILE="$HOME/.chatvsp_secrets"
cat > "$SECRETS_FILE" <<EOF
# ChatVSP Deployment Secrets
# Generated on: $(date)
# KEEP THIS FILE SECURE AND PRIVATE!

Encryption Key: $ENCRYPTION_KEY
Session Secret: $SESSION_SECRET
PostgreSQL Password: $POSTGRES_PASSWORD
DB Readonly Password: $DB_READONLY_PASSWORD
MinIO Password: $MINIO_PASSWORD

Domain: chat.prosourceit.ai
Configuration Location: $DEPLOYMENT_DIR
EOF

chmod 600 "$SECRETS_FILE"

echo "Secrets backed up to: $SECRETS_FILE (secure, readable only by you)"
echo ""
