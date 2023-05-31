#!/bin/bash

set -e

. ./__common_functions.sh
check_root

/usr/local/bin/k3s-uninstall.sh || echo "no previous k3s found"

TOKEN=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 64 ; echo '')
echo using $TOKEN

import __k3s_functions.sh

copyk3sConfig
copyHelmConfig

curl -sfL https://get.k3s.io | K3S_TOKEN=$TOKEN sh -s - server --cluster-init


echo "if that worked you should be able to do:"
GEOFF_K3S_SERVER=10.10.1.2
echo "curl -sfL https://get.k3s.io | K3S_TOKEN=$TOKEN K3S_SERVER=$GEOFF_K3S_SERVER sh -s - server --cluster-init"