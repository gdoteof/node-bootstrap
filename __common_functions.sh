#!/bin/bash

function check_root() {
      set -e
      if [ "$EUID" -ne 0 ]; then
            echo "Please run as root"
            exit
      fi
}

function expect_geoff_disk() {
      set -e
      if [ -z "$GEOFF_DISK" ]; then
            echo "Error: DISK environment variable is not set."
            exit 1
      fi
}

function expect_geoff_creds() {
      set -e
      if [ -z "$GEOFF_K3S_SERVER" ]; then
            echo "Error: \$GEOFF_K3S_SERVER variable is not set."
            exit 1
      fi

      if [ -z "$GEOFF_K3S_TOKEN" ]; then
            echo "Error: \$GEOFF_K3S_TOKEN variable is not set."
            exit 1
      fi
}

function parse_creds() {
      set -e
      # Parse command line arguments
      while [[ $# -gt 0 ]]; do
            key="$1"
            case $key in
            --geoff-k3s-server)
                  if [ ! -z "$GEOFF_K3S_SERVER" ] && [ "$GEOFF_K3S_SERVER" != "$2" ]; then
                        echo "Error: Environment variable GEOFF_K3S_SERVER ($GEOFF_K3S_SERVER) does not match CLI argument ($2)"
                        exit 1
                  fi

                  GEOFF_K3S_SERVER="$2"
                  shift # past argument
                  shift # past value
                  ;;
            --geoff-k3s-token)
                  if [ ! -z "$GEOFF_K3S_TOKEN" ] && [ "$GEOFF_K3S_TOKEN" != "$2" ]; then
                        echo "Error: Environment variable GEOFF_K3S_TOKEN ($GEOFF_K3S_TOKEN) does not match CLI argument ($2)"
                        exit 1
                  fi

                  GEOFF_K3S_TOKEN="$2"
                  shift # past argument
                  shift # past value
                  ;;
            *) # unknown option
                  echo "Unknown option: $key"
                  exit 1
                  ;;
            esac
      done

      export GEOFF_K3S_SERVER
      export GEOFF_K3S_TOKEN
}

# k3s functions

function copyk3sConfig() {
      config_file="k3s-config.yaml"

      # Ensure k3s config directory exists
      mkdir -p /etc/rancher/k3s/

      # Copy the appropriate config file to the k3s config directory
      cp ./k3s/$config_file /etc/rancher/k3s/config.yaml
}

function copyHelmAddons() {
      mkdir -p /var/lib/rancher/k3s/server/manifests/

      cp ./helmAddons/* /var/lib/rancher/k3s/server/manifests/
}

function deleteOldRancher() {
      rm -rf /var/lib/rancher
}

function deleteOldContainerD() {
      rm -rf /var/lib/containerd
}

# disk functions

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

      ceph_devices=$(dmsetup info -c --noheadings 2>/dev/null | awk -F: '{print $GEOFF_DISK}' | grep '^ceph' || :)

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
      expect_geoff_disk
      set -e
      SOURCE_DIR=$1
      PARTITION_NUMBER=$2

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

      echo "Syncing $SOURCE_DIR to ${DISK}p${PARTITION_NUMBER}..."


      echo "Isolating emergency target, this can take a minute while everythign shuts down."
      shutdown_services
      echo "In isolation mode"

      # Mount the partitioned disk
      mount "${DISK}p${PARTITION_NUMBER}" /mnt
      echo "Mounted ${DISK}p${PARTITION_NUMBER} at /mnt"

      # Rsync source directory to the new partition in preparation for mounting
      rsync -avxHAX --exclude=/var/log/* --exclude=/var/cache/* "$SOURCE_DIR" /mnt/

      # Update fstab to mount the new partition at the specified mount point
      MOUNT_POINT="/${SOURCE_DIR##*/}"

      echo "Updating fstab to mount ${DISK}p${PARTITION_NUMBER} at $MOUNT_POINT"

      if grep -q "^${DISK}p${PARTITION_NUMBER}.*$MOUNT_POINT" /etc/fstab; then
            echo "Partition already mounted at $MOUNT_POINT"
            umount /mnt && exit 1
      else
            echo "${DISK}p${PARTITION_NUMBER}  $MOUNT_POINT  xfs  defaults  0 0" >>/etc/fstab
      fi

      echo "Leaving isolation mode, this could also take a minute"
      echo "Left isolation mode"
}

function shutdown_services() {
      echo "Shutting down services..."
      systemctl stop cron || true
      systemctl stop unattended-upgrades || true
      systemctl stop containerd || true
      systemctl stop systemd-udevd || true
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
      local p=$2

      echo "Preparing $DISK for partitioning for rootfs..."
      echo "Making a parition of size $SIZE on $DISK"

      # Create a disk label
      parted -s -- $DISK mklabel gpt


      # Create a partition
      parted -s -- $DISK mkpart primary 0% "$SIZE"

      # Refresh the disk and format the partition as XFS
      partprobe $DISK

      echo "Making an xfs parition of size $SIZE on $DISK"
      local label="${DISK}p${p}"
      echo "Making an xfs parition of size $SIZE on $DISK on $label"
      mkfs.xfs ${label} 
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
