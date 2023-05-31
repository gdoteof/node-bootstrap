#!/bin/bash

/usr/local/bin/k3s-uninstall.sh || echo "no previous k3s found"

source __common_functions.sh
check_root


select_disk
remove_ceph_crypt
wipe_disk

deleteOldRancher

prepare_ceph_device # implies 75% to ceph