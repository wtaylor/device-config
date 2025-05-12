#!/usr/bin/env bash

unset VAULT_USERNAME
unset VAULT_PASSWORD

export VAULT_ADDR="https://vault.willtaylor.info"

if vault token lookup >/dev/null; then
	echo "Already logged in to vault in skipping vault login"
else
	vault login || exit 2
fi

export AWS_ACCESS_KEY_ID="$(vault kv get -mount=kv -field=keyID system/device-config/terraform-backend-credentials)"
export AWS_SECRET_ACCESS_KEY="$(vault kv get -mount=kv -field=applicationKey system/device-config/terraform-backend-credentials)"

export PROXMOX_VE_USERNAME="$(vault kv get -mount=kv -field=username system/device-config/red-squadron-proxmox-credentials)"
export PROXMOX_VE_PASSWORD="$(vault kv get -mount=kv -field=password system/device-config/red-squadron-proxmox-credentials)"
export PROXMOX_VE_SSH_USERNAME="$(vault kv get -mount=kv -field=sshUsername system/device-config/red-squadron-proxmox-credentials)"

exec terraform "$@"
