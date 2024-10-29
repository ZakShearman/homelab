terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.33.0"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "2.16.1"
    }

    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.14.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "../../kubeconfig"
  }
}

provider "kubernetes" {
  config_path = "../../kubeconfig"
}

provider "kubectl" {
  config_path = "../../kubeconfig"
}