#! /bin/bash

DISK_LABEL=OldHome
DISK_FORMAT=ext4
MOUNT_POINT=/mnt/Externo
UUID_REGEX='[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'


function configure_fstab() {
  local uuid=$(lsblk -f | grep $DISK_LABEL | grep -Eo "$UUID_REGEX")
  
  grep -q $uuid /etc/fstab
  if [ $? -eq 1 ]
  then
    sudo cp -b /etc/fstab /etc/fstab.bkp
   # echo -e " * UUID=$uuid\t$MOUNT_POINT\t$DISK_FORMAT\tdefaults,noatime 0 2"

   echo -e "UUID=$uuid $MOUNT_POINT\t$DISK_FORMAT\tdefaults,noatime 0 2" | sudo tee -a /etc/fstab
  fi
}

function main() {
  echo "Configuring FSTAB for $DISK_LABEL"
  configure_fstab
}

main
