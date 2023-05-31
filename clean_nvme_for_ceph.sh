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

blkdiscard $DISK

partprobe $DISK

echo "Formatting on $DISK"

echo "When you are done, give an empty partition and the remaining disk will be left as raw volume for ceph."

function partition_disk() {
  local DISK=$1

  echo "Preparing $DISK for partitioning..."

  # Unmount the disk if it's mounted
  umount $DISK*

  # Remove old partition table
  parted -s $DISK mklabel gpt

    local END=0%
  local DEFAULT_NAME="rancher"
  # Get the total disk size in bytes
  
  local DEFAULT_SIZE="12.5%"

  PARTITION_NUMBER=1
  while true; do
    read -p "Partition name [$DEFAULT_NAME]: " NAME
    NAME=${NAME:-$DEFAULT_NAME}
    DEFAULT_NAME=""
  
    # Break the loop if the name is empty
    if [ -z "$NAME" ]; then
      break
    fi
  
    read -p "Partition size [$DEFAULT_SIZE]: " SIZE
    SIZE=${SIZE:-$DEFAULT_SIZE}
  
    echo "DEBUG--- DISK:$DISK END:$END SIZE:$SIZE"
    # Create a partition
    parted -s -- $DISK mkpart primary "$END" "$SIZE"
  
    # Update the start position for the next partition
    END="$SIZE"
  
    # Refresh the disk and format the partition as XFS
    partprobe $DISK
    mkfs.xfs ${DISK}p${PARTITION_NUMBER}
    echo "DEBUG2--- DISK:$DISK PARTITION_NUMBER:$PARTITION_NUMBER"
  
    echo "Partition $NAME of size $SIZE created and formatted as XFS."
  
    PARTITION_NUMBER=$((PARTITION_NUMBER+1))
  done
  
  # If there's any space left on the disk, create a partition for Ceph
  if [ $END != '100%' ]; then
    parted -s -- $DISK mkpart primary $END 100%

    partprobe $DISK
    pvcreate ${DISK}p${PARTITION_NUMBER}
  
    echo "Remaining space left as a raw volume for Ceph."
  fi

}

partition_disk ${DISK}
