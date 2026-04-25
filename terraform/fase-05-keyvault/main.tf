# ─────────────────────────────────────────────
# Data sources
# ─────────────────────────────────────────────

data "azurerm_resource_group" "lab" {
    name = "rg-vault-ha-lab"
}

data "azurerm_client_config" "current" {}

data "azurerm_user_assigned_identity" "vault_ha_wi" {
    name                = "id-vault-ha-lab"
    resource_group_name = data.azurerm_resource_group.lab.name
}

# ─────────────────────────────────────────────
# Azure Key Vault
# ─────────────────────────────────────────────

resource "azurerm_key_vault" "unseal" {
    name                        = "labvaultunsealb"
    location                    = data.azurerm_resource_group.lab.location
    resource_group_name         = data.azurerm_resource_group.lab.name
    tenant_id                   = data.azurerm_client_config.current.tenant_id
    enabled_for_disk_encryption = true
    purge_protection_enabled    = true
    soft_delete_retention_days  = 7
    enable_rbac_authorization   = true
    sku_name                    = "standard"

    tags = {
        environment = "lab"
        project     = "vault-ha-migration"
    }
}

# ─────────────────────────────────────────────
# RSA Key for Vault auto-unseal
# ─────────────────────────────────────────────

resource "azurerm_key_vault_key" "unseal" {
    name         = "unseal-unseal"
    key_vault_id = azurerm_key_vault.unseal.id
    key_type     = "RSA"
    key_size     = 2048

    key_opts = [
        "decrypt",
        "encrypt",
        "sign",
        "verify",
        "wrapKey",
        "unwrapKey"
    ]

    tags = {
        environment = "lab"
        project     = "vault-ha-migration"
    }
}

# ─────────────────────────────────────────────
# Role Assignments
# ─────────────────────────────────────────────

# MI do Vault pode usar a key (wrap/unwrap)
resource "azurerm_role_assignment" "vault_crypto_user" {
    scope                = azurerm_key_vault.unseal.id
    role_definition_name = "Key Vault Crypto User"
    principal_id         = data.azurerm_user_assigned_identity.vault_ha_wi.principal_id
}

# Tu próprio podes gerir keys (criar, rotacionar, apagar)
resource "azurerm_role_assignment" "self_crypto_officer" {
    scope                = azurerm_key_vault.unseal.id
    role_definition_name = "Key Vault Crypto Officer"
    principal_id         = data.azurerm_client_config.current.object_id
}