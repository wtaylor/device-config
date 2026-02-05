#!/usr/bin/env bash

set -eou pipefail

if [ ! -f /dev/dm-1 ]; then
	udisksctl unlock -b /dev/disk/by-uuid/6453028a-3908-4916-886b-56bec4e04f7c
fi

if [ ! -d /run/media/wtaylor/ROOTS ]; then
	udisksctl mount -b /dev/dm-1 -o ro
fi

if [ ! -f /dev/dm-2 ]; then
	udisksctl unlock -b /dev/disk/by-uuid/175ce636-8661-42fc-9cc4-635ff7b1d5a3
fi

if [ ! -d /run/media/wtaylor/ROOTS2 ]; then
	udisksctl mount -b /dev/dm-2
fi

rsync -iaAXx --delete /run/media/wtaylor/ROOTS/keys /run/media/wtaylor/ROOTS2
rsync -iaAXx --delete /run/media/wtaylor/ROOTS/secrets /run/media/wtaylor/ROOTS2

if [ -d /run/media/wtaylor/ROOTS ]; then
	sync /run/media/wtaylor/ROOTS
	udisksctl unmount -b /dev/dm-1
fi

udisksctl lock -b /dev/disk/by-uuid/6453028a-3908-4916-886b-56bec4e04f7c

if [ -d /run/media/wtaylor/ROOTS2 ]; then
	sync /run/media/wtaylor/ROOTS2
	udisksctl unmount -b /dev/dm-2
fi

udisksctl lock -b /dev/disk/by-uuid/175ce636-8661-42fc-9cc4-635ff7b1d5a3
