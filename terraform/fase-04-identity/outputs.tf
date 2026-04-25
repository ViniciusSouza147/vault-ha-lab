output "identity_client_id" {
    value = azurerm_user_assigned_identity.vault_ha_wi.client_id
}

output "identity_principal_id" {
    value = azurerm_user_assigned_identity.vault_ha_wi.principal_id
}

output "federated_credential_subject" {
    value = azurerm_federated_identity_credential.vault_ha.subject
}