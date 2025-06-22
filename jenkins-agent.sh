#!/bin/bash
set -e

echo "==== Resizing disk... ===="

# Install growpart tool (for expanding partitions)
sudo yum install -y cloud-utils-growpart

# Expand partition (adjust device if yours is different)
sudo growpart /dev/nvme0n1 1

# Expand physical volume (PV)
sudo pvresize /dev/nvme0n1p1

# Extend LVM logical volumes safely
sudo lvextend -r -L +10G /dev/mapper/RootVG-homeVol || echo "homeVol not found"
sudo lvextend -r -L +10G /dev/mapper/RootVG-varVol || echo "varVol not found"
sudo lvextend -r -l +100%FREE /dev/mapper/RootVG-varTmpVol || echo "varTmpVol not found"

echo "==== Installing required packages... ===="

# Java
sudo yum install -y java-17-openjdk

# Terraform
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo
sudo yum install -y terraform
echo 'export PATH=$PATH:/usr/bin' >> ~/.bashrc

# Node.js
sudo dnf module disable nodejs -y
sudo dnf module enable nodejs:20 -y
sudo dnf install -y nodejs

# Zip
sudo yum install -y zip

# Docker
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user

# Helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod +x get_helm.sh
./get_helm.sh
rm -f get_helm.sh

# Maven
sudo dnf install -y maven

# Python 3.11
sudo dnf install -y python3.11 gcc python3-devel

echo "==== Disk Resize & Setup Complete ===="
df -h
