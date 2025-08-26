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
  value = local.subdomain_suffix
}

output "aks_node_agent_pool_label" {
  value = local.node_agent_pool_label
}
