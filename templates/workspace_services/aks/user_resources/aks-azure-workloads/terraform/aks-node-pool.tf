resource "azurerm_kubernetes_cluster_node_pool" "aks" {
  name                        = local.node_agent_pool_label
  kubernetes_cluster_id       = data.azurerm_kubernetes_cluster.aks.id
  vm_size                     = var.node_size
  node_count                  = var.node_count
  temporary_name_for_rotation = "tmp${local.short_service_id}"

  auto_scaling_enabled = var.node_autoscaling_enabled
  max_count            = var.node_autoscaling_max_count
  min_count            = var.node_autoscaling_min_count

  vnet_subnet_id = data.azurerm_subnet.services.id

  upgrade_settings {
    drain_timeout_in_minutes      = 0
    max_surge                     = "10%"
    node_soak_duration_in_minutes = 0
  }

  tags = local.tre_user_resources_tags
}
