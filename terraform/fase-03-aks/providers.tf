terraform {
    required_version = ">= 1.5.0"

    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = "~> 4.0"
        }
        kubernetes = {
            source  = "hashicorp/kubernetes"
            version = "~> 2.25"
        }
    }
}

provider "azurerm" {
    features {}
    subscription_id = "c38404f0-40a4-40aa-afc6-d538cbdbe06b"
}

# ─────────────────────────────────────────────
# Providers
# ─────────────────────────────────────────────

provider "kubernetes" {
    host                   = azurerm_kubernetes_cluster.lab.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.lab.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.lab.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.lab.kube_config[0].cluster_ca_certificate)
}
