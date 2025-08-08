resource "azurerm_kubernetes_cluster_node_pool" "aks" {
  name                        = var.node_agent_pool_label
  kubernetes_cluster_id       = data.azurerm_kubernetes_cluster.aks.id
  vm_size                     = var.node_size
  node_count                  = var.node_count
  temporary_name_for_rotation = "${var.node_agent_pool_label}tmp"

  auto_scaling_enabled = var.node_autoscaling_enabled
  max_count            = var.node_autoscaling_max_count
  min_count            = var.node_autoscaling_min_count

  tags = local.tre_user_resources_tags
}
