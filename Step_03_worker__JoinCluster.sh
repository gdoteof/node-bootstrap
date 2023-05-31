#!/bin/bash
set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "$SCRIPT_DIR/__common_functions.sh"

check_root
/usr/local/bin/k3s-uninstall.sh || echo "no previous k3s found"

parse_creds "$@"
expect_geoff_creds


copyk3sConfig



curl -sfL https://get.k3s.io | K3S_TOKEN=$GEOFF_K3S_TOKEN K3S_SERVER=$GEOFF_K3S_SERVER sh -s - agent