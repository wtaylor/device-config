#!/usr/bin/env bash

if [ -d /run/media/wtaylor/ROOTS ]; then
	sync /run/media/wtaylor/ROOTS
	udisksctl unmount -b /dev/dm-1
fi

udisksctl lock -b /dev/disk/by-uuid/6453028a-3908-4916-886b-56bec4e04f7c
udisksctl power-off -b /dev/disk/by-uuid/6453028a-3908-4916-886b-56bec4e04f7c
