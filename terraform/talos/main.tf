provider "proxmox" {
  endpoint = "https://10.0.10.2:8006/"
  insecure = true # Only needed if your Proxmox server is using a self-signed certificate
}