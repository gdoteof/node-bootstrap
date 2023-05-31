#!/bin/bash

./remove_ceph_crypt.sh

if [ "$EUID" -ne 0 ]
then
  echo "Please run as root"
  exit
fi

FIRST_NVME=$(lsblk -dno NAME,TYPE | grep 'nvme' | grep 'disk' | awk 'NR==1{print $1}')

if [ "$1" == "--first-nvme" ]
then
  DISK="/dev/$FIRST_NVME"
else
  echo "Available physical block devices:"
  lsblk -dno NAME,TYPE,SIZE | grep 'disk' | grep -v 'nbd'
  read -p "Enter the name of the disk to operate on (default is /dev/$FIRST_NVME): " DISK_NAME
  DISK_NAME=${DISK_NAME:-$FIRST_NVME}
  DISK="/dev/$DISK_NAME"
fi

# Check if disk exists
if [ ! -b $DISK ]; then
  echo "Error: Disk $DISK does not exist."
  exit
fi

# Check if disk is mounted
if mount | grep $DISK > /dev/null; then
  echo "Error: Disk $DISK is currently mounted."
  exit
fi

echo "Operating on $DISK"

rm -rf /var/lib/rook

sgdisk --zap-all $DISK

dd if=/dev/zero of="$DISK" bs=1M count=100 oflag=direct,dsync

blkdiscard $DISK

partprobe $DISK

# my version below
# # mine copy-pasted to chat-gpt with some instructions above
# DISK="/dev/nvme0n1"
# 
# rm -rf /var/lib/rook
# 
# # Zap the disk to a fresh, usable state (zap-all is important, b/c MBR has to be clean)
# sgdisk --zap-all $DISK
# 
# # Wipe a large portion of the beginning of the disk to remove more LVM metadata that may be present
# dd if=/dev/zero of="$DISK" bs=1M count=100 oflag=direct,dsync
# 
# # SSDs may be better cleaned with blkdiscard instead of dd
# blkdiscard $DISK
# 
# # Inform the OS of partition table changes
# partprobe $DISK
