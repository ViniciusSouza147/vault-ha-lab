output "aks_name" {
    value = azurerm_kubernetes_cluster.lab.name
}

output "aks_resource_group" {
    value = azurerm_kubernetes_cluster.lab.resource_group_name
}

output "oidc_issuer_url" {
    value = azurerm_kubernetes_cluster.lab.oidc_issuer_url
}

output "kube_config_command" {
    value = "az aks get-credentials --name ${azurerm_kubernetes_cluster.lab.name} --resource-group ${azurerm_kubernetes_cluster.lab.resource_group_name}"
}