terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.112.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.6.1"
    }
  }
}
