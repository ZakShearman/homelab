terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }
    kubectl = {
      source = "gavinbunney/kubectl"
      version = "1.19.0"
    }
    sops = {
      source  = "carlpett/sops"
      version = "1.2.0"
    }
  }
}

provider "kubernetes" {
  config_path    = var.kubeconfig_path
  config_context = var.kubeconfig_context
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
    config_context         = var.kubeconfig_context
  }
}

provider "kubectl" {
  config_path = var.kubeconfig_path
  config_context = var.kubeconfig_context
}