#!/bin/bash
set -e
/usr/local/bin/k3s-uninstall.sh || echo "no previous k3s found"

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
. "$SCRIPT_DIR/__common_functions.sh"


select_disk
remove_ceph_crypt
wipe_disk

deleteOldRancher

prepare_ceph_device # implies 75% to ceph