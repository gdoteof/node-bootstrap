function copyk3sConfig() {
    config_file="k3s-config.yaml"

    # Ensure k3s config directory exists
    mkdir -p /etc/rancher/k3s/

    # Copy the appropriate config file to the k3s config directory
    cp ./k3s/$config_file /etc/rancher/k3s/config.yaml
}

function copyHelmAddons() {
    # Ensure k3s manifests directory exists
    mkdir -p /var/lib/rancher/k3s/server/manifests/

    # Move Helm addons to the k3s manifests directory
    cp ./helmAddons/* /var/lib/rancher/k3s/server/manifests/
}

function deleteOldRancher() {
    rm -rf /var/lib/rancher
}