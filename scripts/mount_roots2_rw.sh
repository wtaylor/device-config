#!/usr/bin/env bash

set -eou pipefail

if [ ! -f /dev/dm-1 ]; then
	udisksctl unlock -b /dev/disk/by-uuid/175ce636-8661-42fc-9cc4-635ff7b1d5a3
fi

if [ ! -d /run/media/wtaylor/ROOTS2 ]; then
	udisksctl mount -b /dev/dm-1
fi
