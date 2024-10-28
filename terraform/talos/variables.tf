variable "proxmox_node_01_name" {
  type    = string
  default = "omen"
}

variable "proxmox_node_02_name" {
  type    = string
  default = "omen"
}

variable "cluster_name" {
  type    = string
  default = "kube"
}

variable "default_gateway" {
  type    = string
  default = "10.0.40.1"
}

variable "kube_control_01_ip_addr" {
  type    = string
  default = "10.0.40.2"
}

variable "kube_worker_01_ip_addr" {
  type    = string
  default = "10.0.40.3"
}