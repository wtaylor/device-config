resource "proxmox_virtual_environment_download_file" "debian_trixie" {
  content_type = "import"
  datastore_id = "local"
  node_name    = local.node_name
  file_name    = "debian-trixie.raw"

  url = "https://cloud.debian.org/images/cloud/trixie/20251117-2299/debian-13-generic-amd64-20251117-2299.raw"
}

