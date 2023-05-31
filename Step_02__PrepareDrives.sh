#!/bin/bash

source __common_functions.sh
check_root

source __disk_functions.sh
select_disk
wipe_disk
partition_disk