locals {
  short_workspace_id = substr(var.tre_resource_id, -4, -1)
  app_insights_name  = "appi-${var.tre_id}-ws-${local.short_workspace_id}"

  grafana_private_endpoint_connection_id = element([
    for connection in data.azapi_resource.azurerm_monitor_workspace.output.properties.privateEndpointConnections
    : connection.id
    if strcontains(connection.name, "grafana")
  ], 0)
}
