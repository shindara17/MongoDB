#!/bin/bash
set -e  # Exit on error

# Update package repositories and install necessary packages
sudo apt update
sudo apt install -y \
    openjdk-11-jdk \
    git \
    maven \
    ca-certificates \
    apt-transport-https \
    curl \
    gnupg-agent \
    software-properties-common

# Install Jenkins
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 5BA31D57EF5975CA
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu
sudo usermod -aG docker $USER

# Install kubectl
curl -LO https://dl.k8s.io/release/v1.21.0/bin/linux/amd64/kubectl
curl -LO https://dl.k8s.io/release/v1.21.0/bin/linux/amd64/kubectl.sha256
echo "$(cat kubectl.sha256) kubectl" | sha256sum --check
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Helm
wget https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz
tar -zxvf helm-v3.2.4-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm

# Configure Helm repositories
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Install MongoDB using Helm
helm install my-mongodb bitnami/mongodb

# Display Jenkins initial admin password
echo 'Clearing screen...' && sleep 5
clear
echo 'Jenkins is installed.'
echo 'Default Jenkins password:' $(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
