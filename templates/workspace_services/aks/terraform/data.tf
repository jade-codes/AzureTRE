data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "ws" {
  name = "rg-${var.tre_id}-ws-${local.short_workspace_id}"
}

data "azurerm_virtual_network" "ws" {
  name                = "vnet-${var.tre_id}-ws-${local.short_workspace_id}"
  resource_group_name = "rg-${var.tre_id}-ws-${local.short_workspace_id}"
}

data "azurerm_route_table" "rt" {
  name                = "rt-${var.tre_id}"
  resource_group_name = local.core_resource_group_name
}

data "azurerm_subnet" "web_apps" {
  name                 = "WebAppsSubnet"
  virtual_network_name = data.azurerm_virtual_network.ws.name
  resource_group_name  = data.azurerm_virtual_network.ws.resource_group_name
}

data "azurerm_subnet" "services" {
  name                 = "ServicesSubnet"
  virtual_network_name = data.azurerm_virtual_network.ws.name
  resource_group_name  = data.azurerm_resource_group.ws.name
}

data "azurerm_container_registry" "mgmt_acr" {
  name                = var.mgmt_acr_name
  resource_group_name = var.mgmt_resource_group_name
}

data "azurerm_log_analytics_workspace" "tre" {
  name                = "log-${var.tre_id}"
  resource_group_name = local.core_resource_group_name
}

data "azurerm_private_dns_zone" "aks" {
  name = "privatelink.${data.azurerm_resource_group.ws.location}.azmk8s.io"
  resource_group_name = local.core_resource_group_name
}

data "azurerm_key_vault" "ws" {
  name                = "kv-${var.tre_id}-ws-${local.short_workspace_id}"
  resource_group_name = data.azurerm_resource_group.ws.name
}
