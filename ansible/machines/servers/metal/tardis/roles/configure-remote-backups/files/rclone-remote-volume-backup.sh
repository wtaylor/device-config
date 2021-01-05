#!/bin/bash

rclone sync /mnt/storage/pvedata/dump/ gdrive-fsb-encrypted: --include "*{lxc-200,lxc-201,lxc-203}*$(date +%Y_%m_%d)*" --delete-excluded -vv
