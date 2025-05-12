locals {
  talos_version = "v1.10.1"
}

data "talos_image_factory_extensions_versions" "red_squadron" {
  talos_version = local.talos_version
  filters = {
    names = [
      "cloudflared",
      "gasket-driver",
      "i915",
      "intel-ice-firmware",
      "intel-ucode",
      "iscsi-tools",
      "mei",
      "nut-client",
      "qemu-guest-agent",
      "thunderbolt",
      "tailscale",
    ]
  }
}

resource "talos_image_factory_schematic" "red_squadron" {
  schematic = yamlencode(
    {
      customization = {
        systemExtensions = {
          officialExtensions = data.talos_image_factory_extensions_versions.red_squadron.extensions_info.*.name
        }
      }
    }
  )
}

data "talos_image_factory_urls" "red_squadron" {
  talos_version = local.talos_version
  schematic_id  = talos_image_factory_schematic.red_squadron.id
  architecture  = "amd64"
  platform      = "nocloud"
}

resource "proxmox_virtual_environment_download_file" "talos_iso" {
  content_type = "iso"
  datastore_id = "local"
  node_name    = "red-one"
  file_name    = "talos-nocloud-amd64.iso"

  url = data.talos_image_factory_urls.red_squadron.urls.iso
}
