#!/usr/bin/env bash

if [ -d /run/media/wtaylor/ROOTS2 ]; then
	sync /run/media/wtaylor/ROOTS2
	udisksctl unmount -b /dev/dm-1
fi

udisksctl lock -b /dev/disk/by-uuid/175ce636-8661-42fc-9cc4-635ff7b1d5a3
udisksctl power-off -b /dev/disk/by-uuid/175ce636-8661-42fc-9cc4-635ff7b1d5a3
