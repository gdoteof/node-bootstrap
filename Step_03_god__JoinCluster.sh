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

parse_creds "$@"

expect_geoff_creds



copyk3sConfigGod


curl -sfL https://get.k3s.io | K3S_TOKEN=$GEOFF_K3S_TOKEN sh -s - server --server https://$GEOFF_K3S_SERVER:6443


echo "./Step_03_god__JoinCluster.sh --geoff-k3s-token $TOKEN --geoff-k3s-server $GEOFF_K3S_SERVER"
echo "./Step_03_god__JoinCluster.sh --geoff-k3s-token $TOKEN --geoff-k3s-server $IP"

echo "./Step_03_worker__JoinCluster.sh --geoff-k3s-token $TOKEN --geoff-k3s-server $GEOFF_K3S_SERVER"
echo "./Step_03_worker__JoinCluster.sh --geoff-k3s-token $TOKEN --geoff-k3s-server $IP"