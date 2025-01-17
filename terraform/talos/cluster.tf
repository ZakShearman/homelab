resource "talos_machine_secrets" "machine_secrets" {}

data "talos_client_configuration" "talosconfig" {
  cluster_name         = var.cluster_name
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  endpoints = [var.kube_control_01_ip_addr]
}

data "talos_machine_configuration" "machineconfig_cp" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.kube_control_01_ip_addr}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets

  config_patches = [
    yamlencode({
      cluster = {
        proxy = {
          mode = "ipvs"
          extraArgs = {
            "ipvs-strict-arp" = "true"
          }
        }
      }
    })
  ]
}

resource "talos_machine_configuration_apply" "cp_config_apply" {
  depends_on = [proxmox_virtual_environment_vm.kube_control_01]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_cp.machine_configuration
  count                       = 1
  node                        = var.kube_control_01_ip_addr
}

data "talos_machine_configuration" "machineconfig_worker" {
  cluster_name     = var.cluster_name
  cluster_endpoint = "https://${var.kube_control_01_ip_addr}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.machine_secrets.machine_secrets
}

resource "talos_machine_configuration_apply" "worker_config_apply" {
  depends_on = [proxmox_virtual_environment_vm.talos_worker_01]
  client_configuration        = talos_machine_secrets.machine_secrets.client_configuration
  machine_configuration_input = data.talos_machine_configuration.machineconfig_worker.machine_configuration
  count                       = 1
  node                        = var.kube_worker_01_ip_addr
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on = [talos_machine_configuration_apply.cp_config_apply]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = var.kube_control_01_ip_addr
}

data "talos_cluster_health" "health" {
  depends_on = [
    talos_machine_configuration_apply.cp_config_apply, talos_machine_configuration_apply.worker_config_apply
  ]
  client_configuration = data.talos_client_configuration.talosconfig.client_configuration
  control_plane_nodes = [var.kube_control_01_ip_addr]
  worker_nodes = [var.kube_worker_01_ip_addr]
  endpoints            = data.talos_client_configuration.talosconfig.endpoints
}

resource "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on = [talos_machine_bootstrap.bootstrap, data.talos_cluster_health.health]
  client_configuration = talos_machine_secrets.machine_secrets.client_configuration
  node                 = var.kube_control_01_ip_addr
}

output "talosconfig" {
  value     = data.talos_client_configuration.talosconfig.talos_config
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.kubeconfig.kubeconfig_raw
  sensitive = true
}