#!/bin/bash

################################################################################
# ChatVSP Azure VM Deployment Script
#
# This script creates an Azure VM with all necessary resources for running
# the ChatVSP application.
#
# Prerequisites:
# - Azure CLI installed and logged in (az login)
# - Subscription selected
#
# Usage: ./deploy-vm.sh
################################################################################

set -e

# Configuration
RESOURCE_GROUP="chatvsp-rg"
LOCATION="eastus"
VM_NAME="chatvsp-vm"
VM_SIZE="Standard_D4s_v3"
VM_IMAGE="Canonical:0001-com-ubuntu-server-focal:20_04-lts-gen2:latest"
ADMIN_USERNAME="azureuser"
VNET_NAME="chatvsp-vnet"
SUBNET_NAME="chatvsp-subnet"
NSG_NAME="chatvsp-nsg"
PUBLIC_IP_NAME="chatvsp-public-ip"
NIC_NAME="chatvsp-nic"
DISK_SIZE_GB=500

echo "================================"
echo "ChatVSP Azure VM Deployment"
echo "================================"
echo ""
echo "Configuration:"
echo "  Resource Group: $RESOURCE_GROUP"
echo "  Location: $LOCATION"
echo "  VM Name: $VM_NAME"
echo "  VM Size: $VM_SIZE (4 vCPU, 16 GB RAM)"
echo "  Disk Size: ${DISK_SIZE_GB} GB"
echo "  Admin User: $ADMIN_USERNAME"
echo ""

read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Deployment cancelled."
    exit 0
fi

echo ""
echo "[1/8] Creating resource group..."
az group create \
    --name "$RESOURCE_GROUP" \
    --location "$LOCATION" \
    --output table

echo ""
echo "[2/8] Creating virtual network..."
az network vnet create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VNET_NAME" \
    --address-prefix 10.0.0.0/16 \
    --subnet-name "$SUBNET_NAME" \
    --subnet-prefix 10.0.1.0/24 \
    --output table

echo ""
echo "[3/8] Creating network security group..."
az network nsg create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$NSG_NAME" \
    --output table

echo ""
echo "[4/8] Adding NSG rules..."
# Allow SSH
az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name "AllowSSH" \
    --priority 1000 \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges 22 \
    --access Allow \
    --protocol Tcp \
    --description "Allow SSH" \
    --output table

# Allow HTTP
az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name "AllowHTTP" \
    --priority 1001 \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges 80 \
    --access Allow \
    --protocol Tcp \
    --description "Allow HTTP" \
    --output table

# Allow HTTPS
az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name "AllowHTTPS" \
    --priority 1002 \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges 443 \
    --access Allow \
    --protocol Tcp \
    --description "Allow HTTPS" \
    --output table

echo ""
echo "[5/8] Creating public IP address..."
az network public-ip create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$PUBLIC_IP_NAME" \
    --sku Standard \
    --allocation-method Static \
    --output table

echo ""
echo "[6/8] Creating network interface..."
az network nic create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$NIC_NAME" \
    --vnet-name "$VNET_NAME" \
    --subnet "$SUBNET_NAME" \
    --public-ip-address "$PUBLIC_IP_NAME" \
    --network-security-group "$NSG_NAME" \
    --output table

echo ""
echo "[7/8] Creating virtual machine..."
echo "This may take 5-10 minutes..."
az vm create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$VM_NAME" \
    --location "$LOCATION" \
    --size "$VM_SIZE" \
    --image "$VM_IMAGE" \
    --admin-username "$ADMIN_USERNAME" \
    --nics "$NIC_NAME" \
    --os-disk-size-gb "$DISK_SIZE_GB" \
    --storage-sku Premium_LRS \
    --generate-ssh-keys \
    --output table

echo ""
echo "[8/8] Retrieving VM information..."
VM_PUBLIC_IP=$(az network public-ip show \
    --resource-group "$RESOURCE_GROUP" \
    --name "$PUBLIC_IP_NAME" \
    --query ipAddress \
    --output tsv)

echo ""
echo "================================"
echo "Deployment Complete!"
echo "================================"
echo ""
echo "VM Details:"
echo "  Name: $VM_NAME"
echo "  Public IP: $VM_PUBLIC_IP"
echo "  Username: $ADMIN_USERNAME"
echo "  SSH Key: ~/.ssh/id_rsa (if generated)"
echo ""
echo "Next Steps:"
echo "  1. Configure DNS A record:"
echo "     chat.prosourceit.ai -> $VM_PUBLIC_IP"
echo ""
echo "  2. Wait for DNS propagation (2-10 minutes), then verify:"
echo "     nslookup chat.prosourceit.ai"
echo ""
echo "  3. Connect to VM:"
echo "     ssh $ADMIN_USERNAME@$VM_PUBLIC_IP"
echo ""
echo "  4. Copy setup scripts to VM:"
echo "     scp deployment/azure/*.sh $ADMIN_USERNAME@$VM_PUBLIC_IP:~/"
echo ""
echo "  5. Run setup on VM:"
echo "     ssh $ADMIN_USERNAME@$VM_PUBLIC_IP"
echo "     chmod +x *.sh"
echo "     ./setup-vm.sh"
echo ""
echo "Deployment information saved to: vm-info.txt"
echo ""

# Save deployment info to file
cat > vm-info.txt <<EOF
ChatVSP Azure Deployment Information
====================================

Deployment Date: $(date)
Resource Group: $RESOURCE_GROUP
Location: $LOCATION

VM Details:
- Name: $VM_NAME
- Size: $VM_SIZE
- Public IP: $VM_PUBLIC_IP
- Admin Username: $ADMIN_USERNAME
- SSH Key: ~/.ssh/id_rsa

Domain Configuration:
- Domain: chat.prosourceit.ai
- DNS A Record: chat.prosourceit.ai -> $VM_PUBLIC_IP

SSH Connection:
ssh $ADMIN_USERNAME@$VM_PUBLIC_IP

Or via domain (after DNS propagation):
ssh $ADMIN_USERNAME@chat.prosourceit.ai
EOF

echo "Saved to: $(pwd)/vm-info.txt"
