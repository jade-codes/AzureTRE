resource "azurerm_user_assigned_identity" "grafana" {
  name                = "gra-identity-${var.tre_id}-ws-${local.short_workspace_id}"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_role_assignment" "grafana_monitoring_reader" {
  scope                = azurerm_monitor_workspace.amw.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azurerm_user_assigned_identity.grafana.principal_id
}

resource "azurerm_role_assignment" "grafana_monitoring_data_reader" {
  scope                = azurerm_monitor_workspace.amw.id
  role_definition_name = "Monitoring Data Reader"
  principal_id         = azurerm_user_assigned_identity.grafana.principal_id
}

resource "azurerm_role_assignment" "grafana_admin_resource_processor" {
  scope                = azurerm_dashboard_grafana.grafana.id
  role_definition_name = "Grafana Admin"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "grafana_admin_users" {
  scope                = azurerm_dashboard_grafana.grafana.id
  role_definition_name = "Grafana Admin"
  principal_id         = var.grafana_admin_id
}
