resource "proxmox_virtual_environment_vm" "kube_control_01" {
  name        = "talos-control-01"
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = var.proxmox_node_01_name
  on_boot     = true

  cpu {
    cores = 2
    type = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
    vlan_id = 40
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.talos_nocloud_image.id
    file_format  = "raw"
    interface    = "virtio0"
    size         = 100
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 5.X.
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = "${var.kube_control_01_ip_addr}/24"
        gateway = var.default_gateway
      }
    }
  }
}

resource "proxmox_virtual_environment_vm" "talos_worker_01" {
  depends_on = [ proxmox_virtual_environment_vm.kube_control_01 ]
  name        = "talos-worker-01"
  description = "Managed by Terraform"
  tags        = ["terraform"]
  node_name   = var.proxmox_node_02_name
  on_boot     = true

  cpu {
    cores = 13
    type = "x86-64-v2-AES"
  }

  memory {
    dedicated = 20480
  }

  agent {
    enabled = true
  }

  network_device {
    bridge = "vmbr0"
    vlan_id = 40
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.talos_nocloud_image.id
    file_format  = "raw"
    interface    = "virtio0"
    size         = 100
  }

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 5.X.
  }

  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = "${var.kube_worker_01_ip_addr}/24"
        gateway = var.default_gateway
      }
    }
  }
}