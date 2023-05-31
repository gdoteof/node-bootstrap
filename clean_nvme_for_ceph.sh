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

echo "Formatting on $DISK"

echo "When you are done, give an empty partition and the remaining disk will be left as raw volume for ceph."

partition_name="rancher"
partition_size="100g"

while true; do
    read -p "Partition name [$partition_name]: " user_partition_name
    read -p "Partition size [$partition_size]: " user_partition_size

    # Use user's input if provided, otherwise use defaults/current values
    partition_name=${user_partition_name:-$partition_name}
    partition_size=${user_partition_size:-$partition_size}

    # Call a function to create the partition with the given name and size
    # create_partition $partition_name $partition_size

    if [[ -z "$user_partition_name" ]]; then
        break
    fi

    # Reset default partition name after first iteration
    partition_name=""
done

while true; do
    read -p "Partition name []: " user_partition_name

    # Call a function to create the partition with the given name
    # create_partition $user_partition_name

    if [[ -z "$user_partition_name" ]]; then
        break
    fi
done

function partition_disk() {
  local DISK=$1

  echo "Preparing $DISK for partitioning..."

  # Unmount the disk if it's mounted
  umount $DISK*

  # Remove old partition table
  parted -s $DISK mklabel gpt

  local END=0
  local DEFAULT_NAME="rancher"
  local DEFAULT_SIZE="100G"

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

    # Create a partition
    parted -s $DISK mkpart primary $END $SIZE

    # Format the partition as XFS
    mkfs.xfs ${DISK}p${NAME}

    # Update the start position for the next partition
    END=$SIZE

    echo "Partition $NAME of size $SIZE created and formatted as XFS."
  done

  # If there's any space left on the disk, create a partition for Ceph
  if [ $END != '100%' ]; then
    parted -s $DISK mkpart primary $END 100%

    # Create a physical volume on the remaining space
    pvcreate ${DISK}p${NAME}

    echo "Remaining space left as a raw volume for Ceph."
  fi
}

partition_disk ${DISK}
