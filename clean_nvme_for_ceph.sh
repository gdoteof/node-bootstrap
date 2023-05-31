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

function partition_disk() {
  local DISK=$1

  echo "Preparing $DISK for partitioning..."

  # Unmount the disk if it's mounted
  umount $DISK*

  # Remove old partition table
  parted -s $DISK mklabel gpt

  local END=0
  local DEFAULT_NAME="rancher"
  # Get the total disk size in bytes
  DISK_SIZE=$(parted -s $DISK unit B print | awk '/^Disk/ {print substr($3, 1, length($3)-1)}')

  # This is the offset for the first partition (1 MiB in sectors)
  OFFSET=2048
  
  # Calculate 10% of the total size for the first partition, in MiB
  FIRST_PARTITION_SIZE_MiB=$(echo "scale=0; (${DISK_SIZE} / 1048576) * 0.10 / 1" | bc)
  # Ensure that the size is a multiple of 1 MiB
  FIRST_PARTITION_SIZE_MiB=$(echo "${FIRST_PARTITION_SIZE_MiB} / 1 * 1" | bc)
  
  # Convert the size back to sectors
  FIRST_PARTITION_SIZE_SECTORS=$(echo "${FIRST_PARTITION_SIZE_MiB} * 2048" | bc)
  
  # Partition start and end position in sectors
  START_SECTOR=$OFFSET
  END_SECTOR=$(echo "$START_SECTOR + $FIRST_PARTITION_SIZE_SECTORS - 1" | bc)
  
<<<<<<< Updated upstream
=======
  # Convert the size to a human-readable format
  HUMAN_READABLE_SIZE=$(numfmt --to=iec-i --suffix=M --format="%.4f" ${FIRST_PARTITION_SIZE_MiB}M)
  
>>>>>>> Stashed changes
  local DEFAULT_SIZE=$HUMAN_READABLE_SIZE;

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
  
    # Create a partition
    parted -s $DISK mkpart primary $END $SIZE
  
    # Update the start position for the next partition
    END=$SIZE
  
    # Format the partition as XFS
    mkfs.xfs ${DISK}p${PARTITION_NUMBER}
  
    echo "Partition $NAME of size $SIZE created and formatted as XFS."
  
    PARTITION_NUMBER=$((PARTITION_NUMBER+1))
  done
  
  # If there's any space left on the disk, create a partition for Ceph
  if [ $END != '100%' ]; then
    parted -s $DISK mkpart primary $END 100%
  
    # Create a physical volume on the remaining space
    pvcreate ${DISK}p${PARTITION_NUMBER}
  
    echo "Remaining space left as a raw volume for Ceph."
  fi

}

partition_disk ${DISK}
