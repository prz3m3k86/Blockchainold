#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

BLUE='\033[1;34m'
NC='\033[0m'  # No Color

PREF_FILE="/etc/apt/preferences.d/nosnap.pref"

echo -e "${BLUE}Removing nosnap.pref file if it exists...${NC}\n"
if [ -e "$PREF_FILE" ]; then
    sudo rm "$PREF_FILE"
    echo -e "${BLUE}nosnap.pref file removed.${NC}\n"
else
    echo -e "${BLUE}nosnap.pref file does not exist.${NC}\n"
fi


echo -e "${BLUE}Updating apt repositories...${NC}\n"
sudo apt update

echo -e "${BLUE}Installing required packages...${NC}\n"
sudo apt-get install wget curl git python3-pip ca-certificates software-properties-common apt-transport-https ca-certificates gnupg gnupg2 build-essential lsb-release snapd pyqt5-dev-tools -y

echo -e "${BLUE}Updating apt packages...${NC}\n"
sudo apt update -y
sudo apt upgrade -y

echo -e "${BLUE}Installing docker...${NC}\n"
sudo apt install docker* -y

echo -e "${BLUE}Adding user 'blockchain' to the 'kvm' group...${NC}\n"
sudo usermod -aG kvm blockchain

echo -e "${BLUE}Downloading minikube...${NC}\n"
sudo wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

echo -e "${BLUE}Copying minikube to /usr/local/bin...${NC}\n"
sudo cp minikube-linux-amd64 /usr/local/bin/minikube
sudo chmod +x /usr/local/bin/minikube

echo -e "${BLUE}Downloading and installing kubectl...${NC}\n"
sudo curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo chmod +x kubectl
sudo mv kubectl /usr/local/bin

echo -e "${BLUE}Creating postgres-data directory...${NC}\n"
mkdir postgres-data

echo -e "${BLUE}Cloning Blockchain repository...${NC}\n"
git clone https://github.com/prz3m3k86/Blockchain.git

echo -e "${BLUE}Adding user 'blockchain' to the 'docker' group...${NC}\n"
sudo usermod -aG docker blockchain

echo -e "${BLUE}Switching group membership to docker and continuing script...${NC}\n"
newgrp docker 

echo -e "${BLUE}Running the second script...${NC}"
bash skrypt2.sh



set -e

BLUE='\033[1;34m'
NC='\033[0m'  # No Color

echo -e "${BLUE}Starting minikube...${NC}\n"
minikube start --mount-string "$HOME/postgres-data:/data" --driver=docker --install-addons=true --kubernetes-version=stable

echo -e "${BLUE}Creating ~/.ssh directory...${NC}\n"
mkdir -p ~/.ssh

echo -e "${BLUE}Configuring kubectl to use minikube context...${NC}\n"
kubectl config use-context minikube

echo -e "${BLUE}Configuring Docker environment variables for minikube...${NC}\n"
eval $(minikube docker-env)

echo -e "${BLUE}Building blockchain image...${NC}\n"
cd Blockchain/blockchain
docker build -t localhost:5000/blockchain .

echo -e "${BLUE}Building blockchain-client image...${NC}\n"
cd ../blockchain_client
docker build -t localhost:5000/blockchain-client .

echo -e "${BLUE}Applying blockchain deployment...${NC}\n"
cd ..
kubectl apply -f blockchain-deployment.yml

echo -e "${BLUE}Applying blockchain-client deployment...${NC}\n"
kubectl apply -f blockchain-client-deployment.yml

kubectl port-forward pods/node1 5001:5001 &
kubectl port-forward pods/node2 5002:5001 &
kubectl port-forward pods/node3 5003:5001 &
kubectl port-forward pods/przemek 8081:8081 &
kubectl port-forward pods/wsei 8082:8081 &

echo -e "${BLUE}Script completed successfully.${NC}\n"