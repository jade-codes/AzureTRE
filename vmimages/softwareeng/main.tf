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

  backend "azurerm" {}
}


provider "azurerm" {
  features {
    key_vault {
      # Don't purge on destroy (this would fail due to purge protection being enabled on keyvault)
      purge_soft_delete_on_destroy               = false
      purge_soft_deleted_secrets_on_destroy      = false
      purge_soft_deleted_certificates_on_destroy = false
      purge_soft_deleted_keys_on_destroy         = false
      # When recreating an environment, recover any previously soft deleted secrets - set to true by default
      recover_soft_deleted_key_vaults   = true
      recover_soft_deleted_secrets      = true
      recover_soft_deleted_certificates = true
      recover_soft_deleted_keys         = true
    }
  }
}


data "azurerm_shared_image_gallery" "vmi_gallery" {
  name                = local.shared_image_gallery_name
  resource_group_name = var.resource_group_name
}

data "azurerm_subscription" "current" {
}

resource "azurerm_shared_image" "softwareengvmi" {
  name                = "softwareengvmi"
  gallery_name        = data.azurerm_shared_image_gallery.vmi_gallery.name
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Windows"
  hyper_v_generation  = "V2"

  identifier {
    publisher = "MSTest"
    offer     = "SEE"
    sku       = "EngineeringSoftwareDevVmImage"
  }
}

module "softwareeng_v1_0_0" {
  source = "./1.0.0"

  tre_id              = var.tre_id
  location            = var.location
  resource_group_name = var.resource_group_name
  tre_core_tags       = local.tre_core_tags
}
