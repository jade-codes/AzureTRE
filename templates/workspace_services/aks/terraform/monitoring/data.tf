data "azurerm_kubernetes_cluster" "aks" {
  resource_group_name = var.resource_group_name
  name                = var.aks_cluster_name
}

data "azurerm_monitor_workspace" "amw" {
  resource_group_name = var.resource_group_name
  name                = var.monitor_workspace_name
}
