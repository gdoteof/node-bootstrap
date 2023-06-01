#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
. "$SCRIPT_DIR/__common_functions.sh"

check_root

/usr/local/bin/k3s-uninstall.sh || echo "no previous k3s found"

select_disk
remove_ceph_crypt
wipe_disk

echo "Deleting old rancher"
deleteOldRancher
deleteOldContainerD

echo "Creating partition"
prepare_xfs_partition "25%" 1
echo "Syncing var to partition"
sync_partition "/var" 1
systemctl default

echo "Preparing ceph device"
prepare_ceph_device # implies 75% to ceph
echo "done"
