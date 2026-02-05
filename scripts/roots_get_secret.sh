#!/usr/bin/env bash

set -eou pipefail

SCRIPT_DIR=$(dirname "$0")

$SCRIPT_DIR/mount_roots.sh >/dev/null

printf "%s" "$(</run/media/wtaylor/ROOTS/secrets/$1)"
