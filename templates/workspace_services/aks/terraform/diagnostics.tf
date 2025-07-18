data "azurerm_monitor_diagnostic_categories" "aks_diagnostic_categories" {
  resource_id = azurerm_kubernetes_cluster.aks.id
}

resource "azurerm_monitor_diagnostic_setting" "aks" {
  name                       = "diag-${local.service_resource_name_suffix}"
  target_resource_id         = azurerm_kubernetes_cluster.aks.id
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.tre.id

  dynamic "enabled_log" {
    for_each = data.azurerm_monitor_diagnostic_categories.aks_diagnostic_categories.log_category_types
    content {
      category = enabled_log.value
    }
  }

  dynamic "enabled_metric" {
    for_each = data.azurerm_monitor_diagnostic_categories.aks_diagnostic_categories.metrics
    content {
      category = enabled_metric.value
    }
  }
}
