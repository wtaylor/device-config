#!/usr/bin/env bash

SCRIPT_DIR=$(dirname "$0")

pushd $SCRIPT_DIR/../terraform/projects/red-squadron
trap "popd" EXIT

unset VAULT_USERNAME
unset VAULT_PASSWORD

export VAULT_ADDR="https://vault.willtaylor.info"

if vault token lookup >/dev/null; then
	echo "Already logged in to vault in skipping vault login"
else
	vault login || exit 2
fi

export AWS_REQUEST_CHECKSUM_CALCULATION=when_required
export AWS_RESPONSE_CHECKSUM_VALIDATION=when_required
export AWS_ACCESS_KEY_ID="$(vault kv get -mount=kv -field=keyID system/device-config/terraform-backend-credentials)"
export AWS_SECRET_ACCESS_KEY="$(vault kv get -mount=kv -field=applicationKey system/device-config/terraform-backend-credentials)"

mkdir -p ~/.talos

terraform output -raw talos_client_config >~/.talos/config
talosctl kubeconfig
