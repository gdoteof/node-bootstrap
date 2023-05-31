#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

if [ $# -ne 1 ]; then
echo "Please provide exactly one argument, the token"
exit 1
fi

TOKEN=$1
echo secret is $TOKEN



config_file="k3s-config.yaml"

# Ensure k3s config directory exists
mkdir -p /etc/rancher/k3s/

# Copy the appropriate config file to the k3s config directory
cp ./k3s/$config_file /etc/rancher/k3s/config.yaml

# Check if the copy operation was successful
if [ $? -eq 0 ]; then
  echo "Configuration file copied successfully."
else
  echo "Failed to copy configuration file."
  exit 1
fi



curl -sfL https://get.k3s.io | K3S_TOKEN=$TOKEN sh -s - server --server https://10.10.1.2:6443
