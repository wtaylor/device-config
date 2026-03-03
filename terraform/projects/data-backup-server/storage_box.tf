data "hcloud_ssh_key" "nebuchadnezzar" {
  name = "wtaylor@nebuchadnezzar"
}

data "vault_kv_secret_v2" "hetzner_credentials" {
  mount = "kv"
  name  = "system/device-config/hetzner-hcloud-token"
}

data "vault_kv_secret_v2" "data_backup_server_ssh" {
  mount = "kv"
  name  = "system/device-config/data-backup-server/storage-box-ssh"
}

resource "hcloud_ssh_key" "data_backup_server" {
  name       = "rclone@data-backup-server"
  public_key = data.vault_kv_secret_v2.data_backup_server_ssh.data.publicKey
}

resource "hcloud_storage_box" "backup_server" {
  name             = "backup-server"
  storage_box_type = "bx21" # 5TB
  location         = "fsn1" # Germany
  password         = data.vault_kv_secret_v2.hetzner_credentials.data.storageBoxPassword

  ssh_keys = [
    hcloud_ssh_key.data_backup_server.public_key,
    data.hcloud_ssh_key.nebuchadnezzar.public_key
  ]

  access_settings = {
    reachable_externally = true
    ssh_enabled          = true
    zfs_enabled          = true
  }

  snapshot_plan = {
    max_snapshots = 14
    hour          = 12
    minute        = 0
  }

  lifecycle {
    ignore_changes  = [ssh_keys]
    prevent_destroy = true
  }
}
