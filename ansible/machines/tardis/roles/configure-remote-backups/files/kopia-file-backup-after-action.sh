#!/bin/bash

SNAPSHOT_ID="kopia-${KOPIA_SNAPSHOT_ID:0:6}"

echo "Snapshot ID: $SNAPSHOT_ID"

/root/proxmox-lxc-zfs-snapback/snapback.py --id "$SNAPSHOT_ID" umount --mountpoint /mnt/backup/ct-snapback
/root/proxmox-lxc-zfs-snapback/snapback.py --id "$SNAPSHOT_ID" destroy
