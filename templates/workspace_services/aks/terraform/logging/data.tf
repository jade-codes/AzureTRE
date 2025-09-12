data "azurerm_kubernetes_cluster" "aks" {
  resource_group_name = var.resource_group_name
  name                = var.aks_cluster_name
}

data "azurerm_log_analytics_workspace" "workspace" {
  resource_group_name = var.resource_group_name
  name                = var.log_analytics_workspace_name
}
