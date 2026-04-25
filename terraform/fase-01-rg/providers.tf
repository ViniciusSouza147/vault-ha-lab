terraform {
    required_version = ">= 1.5.4"
    required_providers {
        azurerm = {
            source = "hashicorp/azurerm"
            version = "~> 4.0"
        }
    }
}

provider "azurerm" {
    features {}
    subscription_id = "c38404f0-40a4-40aa-afc6-d538cbdbe06b"
}