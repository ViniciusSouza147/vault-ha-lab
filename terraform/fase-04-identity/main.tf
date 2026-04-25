# ─────────────────────────────────────────────
# Data sources
# ─────────────────────────────────────────────

data "azurerm_resource_group" "lab" {
    name = "rg-vault-ha-lab"
}

data "azurerm_kubernetes_cluster" "lab" {
    name                = "aks-vault-ha-lab"
    resource_group_name = data.azurerm_resource_group.lab.name
}

# ─────────────────────────────────────────────
# User-Assigned Managed Identity
# ─────────────────────────────────────────────

resource "azurerm_user_assigned_identity" "vault_ha_wi" {
    name                = "id-vault-ha-lab"
    resource_group_name = data.azurerm_resource_group.lab.name
    location            = data.azurerm_resource_group.lab.location

    tags = {
        environment = "lab"
        project     = "vault-ha-migration"
    }
}

# ─────────────────────────────────────────────
# Federated Identity Credential
# ─────────────────────────────────────────────

resource "azurerm_federated_identity_credential" "vault_ha" {
    name                = "fed-vault-ha-sa"
    resource_group_name = data.azurerm_resource_group.lab.name
    parent_id           = azurerm_user_assigned_identity.vault_ha_wi.id
    audience            = ["api://AzureADTokenExchange"]
    issuer              = data.azurerm_kubernetes_cluster.lab.oidc_issuer_url
    subject             = "system:serviceaccount:vault-ha:vault-ha"
}