#!/bin/bash

# Prompt for master or worker
echo "Enter [m] for master configuration or [w] for worker configuration: "
read choice

# Set config file based on choice
if [ "$choice" == "m" ]; then
  config_file="master-config.yaml"
elif [ "$choice" == "w" ]; then
  config_file="worker-config.yaml"
else
  echo "Invalid choice. Please enter 'm' for master or 'w' for worker."
  exit 1
fi

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
mv ./* /var/lib/rancher/k3s/server/manifests/

# Check if the move operation was successful
if [ $? -eq 0 ]; then
  echo "Helm addons moved successfully."
else
  echo "Failed to move Helm addons."
  exit 1
fi

exit 0

