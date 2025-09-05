resource "azurerm_shared_image_gallery" "vmi_gallery" {
  name                = local.shared_image_gallery_name
  location            = var.location
  resource_group_name = var.resource_group_name
  description         = "Gallery for all SEE related Virtual Machine Images"
  tags                = var.tre_core_tags
}

resource "azurerm_storage_account" "software" {
  name                             = local.software_storage_account_name
  location                         = var.location
  resource_group_name              = var.resource_group_name
  account_tier                     = "Standard"
  account_replication_type         = "GRS"
  https_traffic_only_enabled       = true
  allow_nested_items_to_be_public  = false
  cross_tenant_replication_enabled = false
  shared_access_key_enabled        = false
  local_user_enabled               = false
  tags                             = local.security_control_tags

  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      customer_managed_key,
      identity
    ]
  }
}

resource "azurerm_storage_container" "installers" {
  name                  = "installers"
  storage_account_id    = azurerm_storage_account.software.id
  container_access_type = "private"
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_private_endpoint" "webpe" {
  name                = "pe-web-${local.software_storage_account_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.shared_subnet
  tags                = var.tre_core_tags

  lifecycle { ignore_changes = [tags] }

  private_dns_zone_group {
    name                 = "private-dns-zone-group-software"
    private_dns_zone_ids = [var.vm_image_build_software_dns_zone_id]
  }

  private_service_connection {
    name                           = "psc-web-${local.software_storage_account_name}"
    private_connection_resource_id = azurerm_storage_account.software.id
    is_manual_connection           = false
    subresource_names              = ["Blob"]
  }
}
