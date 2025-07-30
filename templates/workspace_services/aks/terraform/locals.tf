locals {
  short_service_id             = substr(var.id, -4, -1)
  short_workspace_id           = substr(var.workspace_id, -4, -1)
  service_resource_name_suffix = "${var.tre_id}-ws-${local.short_workspace_id}-svc-${local.short_service_id}"
  core_resource_group_name     = "rg-${var.tre_id}"

  tre_workspace_service_tags = {
    tre_id                   = var.tre_id
    tre_workspace_id         = var.workspace_id
    tre_workspace_service_id = var.id
  }
}
