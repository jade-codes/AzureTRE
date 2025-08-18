output "aks_private_dns_zone" {
  value = data.azurerm_private_dns_zone.aks.name
}

output "aks_cluster_name" {
  value = data.azurerm_kubernetes_cluster.aks.name
}

output "aks_resource_group_name" {
  value = data.azurerm_kubernetes_cluster.aks.resource_group_name
}

output "aks_subdomain_suffix" {
  value = "${var.node_agent_pool_label}-${local.short_parent_id}-${var.environment_type}-${local.short_service_id}"
}
