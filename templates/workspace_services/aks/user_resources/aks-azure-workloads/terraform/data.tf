data "azurerm_resource_group" "ws" {
  name = "rg-${var.tre_id}-ws-${local.short_workspace_id}"
}

data "azurerm_virtual_network" "ws" {
  name                = "vnet-${var.tre_id}-ws-${local.short_workspace_id}"
  resource_group_name = data.azurerm_resource_group.ws.name
}

data "azurerm_subnet" "services" {
  name                 = "ServicesSubnet"
  virtual_network_name = data.azurerm_virtual_network.ws.name
  resource_group_name  = data.azurerm_resource_group.ws.name
}

data "azurerm_private_dns_zone" "aks" {
  name = "privatelink.${data.azurerm_resource_group.ws.location}.azmk8s.io"
}

data "azurerm_kubernetes_cluster" "aks" {
  name                = local.parent_service_resource_name_suffix
  resource_group_name = data.azurerm_resource_group.ws.name
}
