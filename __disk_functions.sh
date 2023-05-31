source __common_functions.sh

function partition_disk() {
    expect_geoff_disk

    local DISK=$GEOFF_DISK

    echo "Preparing $DISK for partitioning..."

    # Unmount the disk if it's mounted
    umount $DISK*

    # Remove old partition table
    parted -s $DISK mklabel gpt

    local END=0%
    local DEFAULT_NAME="var"
    # Get the total disk size in bytes

    local DEFAULT_SIZE="25%"

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

        PARTITION_NUMBER=$((PARTITION_NUMBER + 1))
    done

    # If there's any space left on the disk, create a partition for Ceph
    if [ $END != '100%' ]; then
        parted -s -- $DISK mkpart primary $END 100%

        partprobe $DISK
        pvcreate ${DISK}p${PARTITION_NUMBER}

        echo "Remaining space left as a raw volume for Ceph."
    fi

}

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

function wipe_disk() {
    expect_geoff_disk
    sgdisk --zap-all $GEOFF_DISK
    blkdiscard $GEOFF_DISK
    partprobe $GEOFF_DISK
}