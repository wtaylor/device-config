#!/usr/bin/env bash

unset VAULT_USERNAME
unset VAULT_PASSWORD

export VAULT_ADDR="https://vault.willtaylor.info"

if [ -z "$1" ]; then
	exit 1
fi

if [ -z "$2" ]; then
	vault kv get -mount=kv "$1"
	exit $?
fi

vault kv get -mount=kv -field="$2" "$1"
