resource "azurerm_monitor_data_collection_endpoint" "dce" {
  name                          = "MSCI-config-${data.azurerm_kubernetes_cluster.aks.name}"
  resource_group_name           = var.resource_group_name
  location                      = var.location
  kind                          = "Linux"
  public_network_access_enabled = false
}

resource "azurerm_monitor_private_link_scoped_service" "config_dce_connection" {
  name                = "MSCI-config-${var.location}-${var.aks_cluster_name}-connection"
  resource_group_name = var.resource_group_name
  scope_name          = var.private_link_scope_name
  linked_resource_id  = azurerm_monitor_data_collection_endpoint.dce.id
}
