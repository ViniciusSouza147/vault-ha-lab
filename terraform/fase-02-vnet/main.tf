data "azurerm_resource_group" "lab" {
    name = "rg-vault-ha-lab"
}

resource "azurerm_virtual_network" "lab" {
    name                = "vnet-vault-ha-lab"
    location            = data.azurerm_resource_group.lab.location
    resource_group_name = data.azurerm_resource_group.lab.name
    address_space       = ["10.0.0.0/16"]

    tags = {
        environment = "lab"
        project     = "vault-ha-migration"
    }
}

resource "azurerm_subnet" "aks" {
    name                 = "snet-aks"
    resource_group_name  = data.azurerm_resource_group.lab.name
    virtual_network_name = azurerm_virtual_network.lab.name
    address_prefixes     = ["10.0.1.0/24"]
}