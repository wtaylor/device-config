#!/usr/bin/env bash

set -eou pipefail

if [ ! -b /dev/dm-1 ]; then
	udisksctl unlock -b /dev/disk/by-uuid/6453028a-3908-4916-886b-56bec4e04f7c
fi

if [ ! -d /run/media/wtaylor/ROOTS ]; then
	udisksctl mount -b /dev/dm-1 -o ro
fi
