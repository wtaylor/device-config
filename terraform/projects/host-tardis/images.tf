resource "proxmox_virtual_environment_download_file" "debian_trixie" {
  content_type = "import"
  datastore_id = "local"
  node_name    = local.node_name
  file_name    = "debian-trixie.raw"

  url = "https://cloud.debian.org/images/cloud/trixie/20251117-2299/debian-13-generic-amd64-20251117-2299.raw"
}

resource "proxmox_virtual_environment_download_file" "fedora_coreos" {
  content_type            = "iso"
  datastore_id            = "local"
  node_name               = local.node_name
  file_name               = "coreos.iso"
  decompression_algorithm = "zst"

  url = "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/43.20251214.3.0/x86_64/fedora-coreos-43.20251214.3.0-proxmoxve.x86_64.qcow2.xz"
}

