#!/bin/bash
set -e
/usr/local/bin/k3s-uninstall.sh || echo "no previous k3s found"

source __common_functions.sh
check_root


select_disk
remove_ceph_crypt
wipe_disk

deleteOldRancher

prepare_xfs_partition "25%"
sync_partition "/var" $GEOFF_DISK 1

prepare_ceph_device # implies 75% to ceph

move_var_to_nvme