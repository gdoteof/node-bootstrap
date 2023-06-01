#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "$SCRIPT_DIR/__common_functions.sh"

check_root
/usr/local/bin/k3s-uninstall.sh || echo "no previous k3s server found"
/usr/local/bin/k3s-killall.sh || echo "no previous k3s agent stuff found"
/usr/local/bin/k3s-agent-uninstall.sh || echo "no previous k3s agent stuff found"

parse_creds "$@"
expect_geoff_creds


copyk3sConfigAgent



echo "Join with token $GEOFF_K3S_TOKEN to server $GEOFF_K3S_SERVER"
curl -sfL https://get.k3s.io | K3S_TOKEN=$GEOFF_K3S_TOKEN K3S_SERVER=$GEOFF_K3S_SERVER sh -s - agent