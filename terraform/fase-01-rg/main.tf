resource "azurerm_resource_group" "lab" {
    name     = "rg-vault-ha-lab"
    location = "West Europe"

    tags = {
        environment = "lab"
        project     = "vault-ha-migration"
        owner       = "Marcus V S Freitas"
    }  
}