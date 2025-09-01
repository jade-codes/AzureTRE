locals {
  short_service_id   = substr(var.tre_resource_id, -4, -1)
  short_workspace_id = substr(var.workspace_id, -4, -1)
  short_parent_id    = substr(var.parent_service_id, -4, -1)

  node_agent_pool_label = replace("${var.workload_type}${var.environment_type}${local.short_service_id}", "-", "")
  subdomain_suffix      = "${var.workload_type}-${var.environment_type}-${local.short_service_id}"

  workspace_resource_name_suffix      = "${var.tre_id}-ws-${local.short_workspace_id}"
  parent_service_resource_name_suffix = "aks-${var.tre_id}-ws-${local.short_workspace_id}-svc-${local.short_parent_id}"
  service_resource_name_suffix        = "aks-${var.tre_id}-ws-${local.short_workspace_id}-svc-${local.short_parent_id}-${local.short_service_id}"

  tre_user_resources_tags = {
    tre_id                   = var.tre_id
    tre_workspace_id         = var.workspace_id
    tre_workspace_service_id = var.parent_service_id
    tre_user_resource_id     = var.tre_resource_id
  }
}
