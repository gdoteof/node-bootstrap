# source __common_functions.sh

function remove_ceph_crypt() {
    expect_geoff_disk

    crypt_devices=$(dmsetup info -c --noheadings | grep 'CRYPT-' | awk -F: '{print $GEOFF_DISK}')

    if [ -z "$crypt_devices" ]; then
        echo "No devices with UUIDs starting with 'CRYPT-' found."
    else
        echo "Removing devices with UUIDs starting with 'CRYPT-':"
        for device in $crypt_devices; do
            echo "Removing $device"
            dmsetup remove "$device"
        done
    fi

    ceph_devices=$(dmsetup info -c --noheadings | awk -F: '{print $GEOFF_DISK}' | grep '^ceph')

    if [ -z "$ceph_devices" ]; then
        echo "No devices with names starting with 'ceph' found."
    else
        echo "Removing devices with names starting with 'ceph':"
        for device in $ceph_devices; do
            echo "Removing $device"
            dmsetup remove "$device"
        done
    fi

}

function select_disk() {
    echo "Available physical block devices:"
    lsblk -dno NAME,TYPE,SIZE | grep 'disk' | grep -v 'nbd'
    read -p "Enter the name of the disk to operate on: " DISK_NAME
    DISK="/dev/$DISK_NAME"

    # Check if disk exists
    if [ ! -b $DISK ]; then
        echo "Error: Disk $DISK does not exist."
        exit
    fi

    # Check if disk is mounted
    if mount | grep $DISK >/dev/null; then
        echo "Error: Disk $DISK is currently mounted."
        exit
    fi

    export GEOFF_DISK=$DISK
}

function sync_partition() {
    set -e
    $SOURCE_DIR=$1
    $DISK=$2
    $PARTITION_NUMBER=$3

    # Check if source directory exists
    if [ ! -d "$SOURCE_DIR" ]; then
        echo "Error: Source directory $SOURCE_DIR does not exist."
        exit 1
    fi

    # Check if partition number is valid
    if [[ ! "$PARTITION_NUMBER" =~ ^[0-9]+$ ]]; then
        echo "Error: Partition number must be a positive integer."
        exit 1
    fi

    # Stop all services
    systemctl stop *

    # Mount the partitioned disk
    mount "${DISK}p${PARTITION_NUMBER}" /mnt

    # Rsync source directory to the new partition in preparation for mounting
    rsync -avxHAX --exclude=/var/log/* --exclude=/var/cache/* "$SOURCE_DIR" /mnt/

    # Update fstab to mount the new partition at the specified mount point
    MOUNT_POINT="/${SOURCE_DIR##*/}"

    if grep -q "^${DISK}p${PARTITION_NUMBER}.*$MOUNT_POINT" /etc/fstab; then
        echo "Partition already mounted at $MOUNT_POINT"
        umount /mnt && exit 1
    else
        echo "${DISK}p${PARTITION_NUMBER}  $MOUNT_POINT  xfs  defaults  0 0" >>/etc/fstab
    fi
}

function wipe_disk() {
    expect_geoff_disk
    sgdisk --zap-all $GEOFF_DISK
    blkdiscard $GEOFF_DISK
    partprobe $GEOFF_DISK
}

function prepare_xfs_partition() {
    expect_geoff_disk
    local DISK=$GEOFF_DISK
    local SIZE=$1

    echo "Preparing $DISK for partitioning..."

    # Create a partition
    parted -s -- $DISK mkpart primary 0% "$SIZE"

    # Refresh the disk and format the partition as XFS
    partprobe $DISK
    mkfs.xfs ${DISK}p1
}

function prepare_ceph_device() {
    expect_geoff_disk
    local DISK=$GEOFF_DISK

    echo "Preparing remaining space on $DISK as a raw volume for Ceph."

    if [ $(parted -s -- $DISK print free | awk '/^Free Space/ {print $3}') != '100%' ]; then
        parted -s -- $DISK mkpart primary $(parted -s -- $DISK print free | awk '/^Free Space/ {print $2}') 100%
        partprobe $DISK
        pvcreate ${DISK}p2

        echo "Remaining space left as a raw volume for Ceph."
    fi
}
