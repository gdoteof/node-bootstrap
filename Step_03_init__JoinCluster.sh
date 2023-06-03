#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "$SCRIPT_DIR/__common_functions.sh"

check_root

IP=$(ifconfig | grep "inet 10.10.1" | awk '{print $2}' | cut -d ':' -f2 | head -n 1)
if [ -z "$IP" ]; then
  echo "Error: No IP address found for 10.10.1.x network"
  exit 1
fi

/usr/local/bin/k3s-uninstall.sh || echo "no previous k3s found"

TOKEN=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 64 ; echo '')
echo using $TOKEN

copyk3sConfigGod
copyHelmAddons

curl -sfL https://get.k3s.io | K3S_TOKEN=$TOKEN sh -s - server --cluster-init

echo "if that worked you should be able to do:"
GEOFF_K3S_SERVER=$IP
echo "./Step_03_god__JoinCluster.sh --geoff-k3s-token $TOKEN --geoff-k3s-server $GEOFF_K3S_SERVER"
echo "or"
echo "./Step_03_worker__JoinCluster.sh --geoff-k3s-token $TOKEN --geoff-k3s-server $GEOFF_K3S_SERVER"