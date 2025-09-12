resource "azurerm_monitor_workspace" "amw" {
  name                = "amw-${var.tre_id}-ws-${local.short_workspace_id}"
  resource_group_name = var.resource_group_name
  location            = var.location

  public_network_access_enabled = false
}

resource "azurerm_private_endpoint" "prometheus" {
  name                = "pe-prometheus-${var.tre_id}-ws-${local.short_workspace_id}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.workspace_subnet_id

  private_service_connection {
    name                           = "psc-prometheus-${var.tre_id}-ws-${local.short_workspace_id}"
    private_connection_resource_id = azurerm_monitor_workspace.amw.id
    subresource_names              = ["prometheusMetrics"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "prometheus-private-dns-zone-group"
    private_dns_zone_ids = [var.azure_monitor_prometheus_dns_zone_id]
  }
}
