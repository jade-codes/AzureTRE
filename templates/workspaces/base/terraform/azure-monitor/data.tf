data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "rg" {
  name = var.resource_group_name
}

data "azapi_resource_list" "monitor_workspace_private_endpoint_connections" {
  type                   = "Microsoft.Monitor/accounts/privateEndpointConnections@2023-04-03"
  parent_id              = azurerm_monitor_workspace.amw.id
  response_export_values = ["*"]

  depends_on = [
    azurerm_dashboard_grafana_managed_private_endpoint.grafana
  ]
}

data "azapi_resource" "azurerm_monitor_workspace" {
  type                   = "Microsoft.Monitor/accounts@2023-04-03"
  resource_id            = azurerm_monitor_workspace.amw.id
  response_export_values = ["properties.privateEndpointConnections"]
  depends_on = [
    azurerm_dashboard_grafana_managed_private_endpoint.grafana
  ]
}
