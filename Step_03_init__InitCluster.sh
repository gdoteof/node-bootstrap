#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
  echo "Please run as root."
  exit 1
fi

/usr/local/bin/k3s-uninstall.sh || echo "no previous k3s found"

TOKEN=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 64 ; echo '')
echo using $TOKEN

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

# Ensure k3s manifests directory exists
mkdir -p /var/lib/rancher/k3s/server/manifests/

# Move Helm addons to the k3s manifests directory
cp ./helmAddons/* /var/lib/rancher/k3s/server/manifests/

# Check if the move operation was successful
if [ $? -eq 0 ]; then
  echo "Helm addons moved successfully."
else
  echo "Failed to move Helm addons."
  exit 1
fi

curl -sfL https://get.k3s.io | K3S_TOKEN=$TOKEN sh -s - server --cluster-init
