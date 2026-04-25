output "key_vault_name" {
    value = azurerm_key_vault.unseal.name
}

output "key_vault_uri" {
    value = azurerm_key_vault.unseal.vault_uri
}

output "key_name" {
    value = azurerm_key_vault_key.unseal.name
}