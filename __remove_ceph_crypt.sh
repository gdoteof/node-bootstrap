#!/bin/bash

if [ "$EUID" -ne 0 ]
  then echo "Please run as root"
  exit
fi

crypt_devices=$(dmsetup info -c --noheadings | grep 'CRYPT-' | awk -F: '{print $1}')

if [ -z "$crypt_devices" ]
then
      echo "No devices with UUIDs starting with 'CRYPT-' found."
else
      echo "Removing devices with UUIDs starting with 'CRYPT-':"
      for device in $crypt_devices; do
          echo "Removing $device"
          dmsetup remove "$device"
      done
fi

ceph_devices=$(dmsetup info -c --noheadings | awk -F: '{print $1}' | grep '^ceph')

if [ -z "$ceph_devices" ]
then
      echo "No devices with names starting with 'ceph' found."
else
      echo "Removing devices with names starting with 'ceph':"
      for device in $ceph_devices; do
          echo "Removing $device"
          dmsetup remove "$device"
      done
fi

