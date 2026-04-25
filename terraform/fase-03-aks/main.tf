# ─────────────────────────────────────────────
# Data sources: ler recursos das fases anteriores
# ─────────────────────────────────────────────

data "azurerm_resource_group" "lab" {
    name = "rg-vault-ha-lab"
}

data "azurerm_subnet" "aks" {
    name                 = "snet-aks"
    resource_group_name  = data.azurerm_resource_group.lab.name
    virtual_network_name = "vnet-vault-ha-lab"
}

# ─────────────────────────────────────────────
# AKS cluster
# ─────────────────────────────────────────────

resource "azurerm_kubernetes_cluster" "lab" {
    name                = "aks-vault-ha-lab"
    location            = data.azurerm_resource_group.lab.location
    resource_group_name = data.azurerm_resource_group.lab.name
    dns_prefix          = "aks-vault-lab"

    kubernetes_version  = "1.33"

    # --- Identidade do cluster (como o AKS se autentica no Azure) ---
    identity {
        type = "SystemAssigned"
    }

    default_node_pool {
        name                        = "default"
        node_count                  = 1
        vm_size                     = "Standard_b2s_v2"
        vnet_subnet_id              = data.azurerm_subnet.aks.id
        os_disk_size_gb             = 30
        temporary_name_for_rotation = "temppool"
    }

    # --- Rede ---
    network_profile {
        network_plugin = "azure"
        service_cidr   = "10.1.0.0/16"
        dns_service_ip = "10.1.0.10"
    }

    # --- OIDC + Workload Identity (essenciais para Vault auto-unseal) ---
    oidc_issuer_enabled       = true
    workload_identity_enabled = true

    tags = {
        environment = "lab"
        project     = "vault-ha-migration"
    }
}