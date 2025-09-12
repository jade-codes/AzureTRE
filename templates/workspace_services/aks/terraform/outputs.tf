output "aks_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.id
}

output "aks_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_fqdn" {
  description = "The FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.aks.fqdn
}

output "aks_node_resource_group" {
  description = "The resource group for the AKS cluster nodes"
  value       = azurerm_kubernetes_cluster.aks.node_resource_group
}

output "aks_identity_principal_id" {
  description = "The principal ID of the AKS managed identity"
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

output "workspace_address_space" {
  value = jsonencode(data.azurerm_virtual_network.ws.address_space)
}

output "grafana_endpoint" {
  value = data.azurerm_dashboard_grafana.grafana.endpoint
}

output "prometheus_workspace_id" {
  value = data.azurerm_monitor_workspace.amw.id
}
